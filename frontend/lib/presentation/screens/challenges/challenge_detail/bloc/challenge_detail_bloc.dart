import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../../domain/models/challenges/challenge_draft.dart';
import '../../../../../domain/models/challenges/challenge_outcome.dart';
import '../../../../../domain/models/challenges/challenge_progress_entry.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/challenges/clone_challenge_use_case.dart';
import '../../../../../domain/use_cases/challenges/delete_challenge_use_case.dart';
import '../../../../../domain/use_cases/challenges/get_challenge_file_url_use_case.dart';
import '../../../../../domain/use_cases/challenges/get_challenge_use_case.dart';
import '../../../../../domain/use_cases/challenges/list_challenge_progress_use_case.dart';
import '../../../../../domain/use_cases/challenges/list_challenge_subjects_use_case.dart';
import '../../../../../domain/use_cases/challenges/record_challenge_progress_use_case.dart';
import '../../../../../domain/use_cases/challenges/reorder_milestones_use_case.dart';
import '../../../../../domain/use_cases/challenges/set_challenge_completion_use_case.dart';
import '../../../../../domain/use_cases/challenges/set_milestone_completion_use_case.dart';
import '../../../../../domain/use_cases/challenges/update_challenge_use_case.dart';

part 'challenge_detail_bloc.freezed.dart';
part 'challenge_detail_event.dart';
part 'challenge_detail_state.dart';

/// Detalle de un reto: progreso, tareas, historial y acciones del dueño
/// (o clonado si es ajeno).
class ChallengeDetailBloc
    extends Bloc<ChallengeDetailEvent, ChallengeDetailState> {
  ChallengeDetailBloc({
    required this._getChallenge,
    required this._listProgress,
    required this._listSubjects,
    required this._setCompletion,
    required this._setMilestoneCompletion,
    required this._recordProgress,
    required DeleteChallengeUseCaseContract deleteChallenge,
    required CloneChallengeUseCaseContract cloneChallenge,
    required UpdateChallengeUseCaseContract updateChallenge,
    required ReorderMilestonesUseCaseContract reorderMilestones,
    required this._getFileUrl,
    required this._getAccount,
  }) : _delete = deleteChallenge,
       _clone = cloneChallenge,
       _update = updateChallenge,
       _reorder = reorderMilestones,
       super(const ChallengeDetailState()) {
    on<ChallengeDetailStarted>(_onStarted);
    on<ChallengeDetailRefreshed>((_, emit) => _load(emit));
    on<ChallengeDetailChallengeReplaced>(_onReplaced);
    on<ChallengeDetailCompletionToggled>(_onCompletionToggled);
    on<ChallengeDetailMilestoneToggled>(_onMilestoneToggled);
    on<ChallengeDetailProgressRecorded>(_onProgressRecorded);
    on<ChallengeDetailDeleteRequested>(_onDelete);
    on<ChallengeDetailCloneRequested>(_onClone);
    on<ChallengeDetailVisibilityChanged>(_onVisibility);
    on<ChallengeDetailMilestonesReordered>(_onReorder);
    on<ChallengeDetailFileRequested>(_onFile);
  }

  final GetChallengeUseCaseContract _getChallenge;
  final ListChallengeProgressUseCaseContract _listProgress;
  final ListChallengeSubjectsUseCaseContract _listSubjects;
  final SetChallengeCompletionUseCaseContract _setCompletion;
  final SetMilestoneCompletionUseCaseContract _setMilestoneCompletion;
  final RecordChallengeProgressUseCaseContract _recordProgress;
  final DeleteChallengeUseCaseContract _delete;
  final CloneChallengeUseCaseContract _clone;
  final UpdateChallengeUseCaseContract _update;
  final ReorderMilestonesUseCaseContract _reorder;
  final GetChallengeFileUrlUseCaseContract _getFileUrl;
  final GetAccountUseCaseContract _getAccount;

  String? _challengeId;

  Future<void> _onStarted(
    ChallengeDetailStarted event,
    Emitter<ChallengeDetailState> emit,
  ) async {
    _challengeId = event.challengeId;
    emit(state.copyWith(status: ChallengeDetailStatus.loading, error: null));
    await _load(emit);
  }

  Future<void> _load(Emitter<ChallengeDetailState> emit) async {
    final id = _challengeId;
    if (id == null) return;
    final result = await _getChallenge(id);
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: ChallengeDetailStatus.ready,
            challenge: value,
            error: null,
          ),
        );
        await _loadExtras(emit, value);
      case Failure(:final error):
        emit(
          state.copyWith(status: ChallengeDetailStatus.failure, error: error),
        );
    }
  }

  /// Historial y nombre de asignatura: complementarios, sin bloquear la pantalla.
  Future<void> _loadExtras(
    Emitter<ChallengeDetailState> emit,
    Challenge challenge,
  ) async {
    if (!challenge.owned) return;
    final history = await _listProgress(challenge.id);
    String? subjectName = state.subjectName;
    final subjectId = challenge.subjectId;
    if (subjectId != null && subjectName == null) {
      final subjects = (await _listSubjects()).valueOrNull ?? const [];
      for (final s in subjects) {
        if (s.id == subjectId) subjectName = s.name;
      }
    }
    emit(
      state.copyWith(
        history: history.valueOrNull ?? state.history,
        subjectName: subjectId == null ? null : subjectName,
      ),
    );
  }

  Future<void> _onReplaced(
    ChallengeDetailChallengeReplaced event,
    Emitter<ChallengeDetailState> emit,
  ) async {
    final subjectChanged =
        event.challenge.subjectId != state.challenge?.subjectId;
    emit(
      state.copyWith(
        challenge: event.challenge,
        subjectName: subjectChanged ? null : state.subjectName,
      ),
    );
    await _loadExtras(emit, event.challenge);
  }

  Future<void> _onCompletionToggled(
    ChallengeDetailCompletionToggled event,
    Emitter<ChallengeDetailState> emit,
  ) async {
    final challenge = state.challenge;
    if (challenge == null || state.busy) return;
    await _runOutcome(
      emit,
      _setCompletion(challenge.id, completed: !challenge.completed),
    );
  }

  Future<void> _onMilestoneToggled(
    ChallengeDetailMilestoneToggled event,
    Emitter<ChallengeDetailState> emit,
  ) async {
    final challenge = state.challenge;
    final milestone = challenge?.milestoneById(event.milestoneId);
    if (challenge == null || milestone == null || state.busy) return;
    emit(state.copyWith(busyMilestoneId: milestone.id));
    await _runOutcome(
      emit,
      _setMilestoneCompletion(
        challenge.id,
        milestone.id,
        completed: !milestone.completed,
      ),
    );
  }

  Future<void> _onProgressRecorded(
    ChallengeDetailProgressRecorded event,
    Emitter<ChallengeDetailState> emit,
  ) async {
    final challenge = state.challenge;
    if (challenge == null || state.busy) return;
    await _runOutcome(
      emit,
      _recordProgress(
        challenge.id,
        milestoneId: event.milestoneId,
        value: event.value,
      ),
      progress: true,
    );
  }

  /// Aplica una acción que devuelve XP: actualiza el reto, refresca la cuenta
  /// si la XP ha cambiado y avisa de las tareas desbloqueadas.
  Future<void> _runOutcome(
    Emitter<ChallengeDetailState> emit,
    Future<AppResult<ChallengeOutcome>> action, {
    bool progress = false,
  }) async {
    emit(state.copyWith(busy: true));
    final result = await action;
    switch (result) {
      case Success(:final value):
        final account = value.xpDelta != 0
            ? (await _getAccount()).valueOrNull
            : null;
        final unlocked = [
          for (final id in value.unlockedMilestoneIds)
            ?value.challenge.milestoneById(id)?.title,
        ];
        emit(
          state.copyWith(
            challenge: value.challenge,
            busy: false,
            busyMilestoneId: null,
          ),
        );
        _emitEffect(
          emit,
          ChallengeDetailEffect.outcome(
            xpDelta: value.xpDelta,
            unlockedTitles: unlocked,
            challengeCompleted: value.challengeCompleted,
            progressRecorded: progress,
            account: account,
          ),
        );
        if (progress) {
          final history = await _listProgress(value.challenge.id);
          emit(state.copyWith(history: history.valueOrNull ?? state.history));
        }
      case Failure(:final error):
        emit(state.copyWith(busy: false, busyMilestoneId: null));
        _emitEffect(emit, ChallengeDetailEffect.failure(error));
    }
  }

  Future<void> _onDelete(
    ChallengeDetailDeleteRequested event,
    Emitter<ChallengeDetailState> emit,
  ) async {
    final challenge = state.challenge;
    if (challenge == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _delete(challenge.id);
    switch (result) {
      case Success():
        final lost = challenge.totalXpAwarded;
        final account = lost > 0 ? (await _getAccount()).valueOrNull : null;
        emit(state.copyWith(busy: false));
        _emitEffect(
          emit,
          ChallengeDetailEffect.deleted(xpLost: lost, account: account),
        );
      case Failure(:final error):
        emit(state.copyWith(busy: false));
        _emitEffect(emit, ChallengeDetailEffect.failure(error));
    }
  }

  Future<void> _onClone(
    ChallengeDetailCloneRequested event,
    Emitter<ChallengeDetailState> emit,
  ) async {
    final challenge = state.challenge;
    if (challenge == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _clone(challenge.id);
    emit(state.copyWith(busy: false));
    _emitEffect(
      emit,
      result.fold(
        (copy) => ChallengeDetailEffect.cloned(copy.id),
        ChallengeDetailEffect.failure,
      ),
    );
  }

  Future<void> _onVisibility(
    ChallengeDetailVisibilityChanged event,
    Emitter<ChallengeDetailState> emit,
  ) async {
    final challenge = state.challenge;
    if (challenge == null ||
        state.busy ||
        challenge.visibility == event.visibility) {
      return;
    }
    emit(state.copyWith(busy: true));
    final result = await _update(
      challenge.id,
      ChallengeChanges(visibility: event.visibility),
    );
    switch (result) {
      case Success(:final value):
        emit(state.copyWith(busy: false, challenge: value));
        _emitEffect(emit, const ChallengeDetailEffect.saved());
      case Failure(:final error):
        emit(state.copyWith(busy: false));
        _emitEffect(emit, ChallengeDetailEffect.failure(error));
    }
  }

  Future<void> _onReorder(
    ChallengeDetailMilestonesReordered event,
    Emitter<ChallengeDetailState> emit,
  ) async {
    final challenge = state.challenge;
    if (challenge == null || state.busy) return;
    final current = challenge.milestones.map((m) => m.id).toList();
    if (_sameOrder(current, event.milestoneIds)) return;
    emit(state.copyWith(busy: true));
    final result = await _reorder(challenge.id, event.milestoneIds);
    switch (result) {
      case Success(:final value):
        emit(state.copyWith(busy: false, challenge: value));
        _emitEffect(emit, const ChallengeDetailEffect.saved());
      case Failure(:final error):
        emit(state.copyWith(busy: false));
        _emitEffect(emit, ChallengeDetailEffect.failure(error));
    }
  }

  Future<void> _onFile(
    ChallengeDetailFileRequested event,
    Emitter<ChallengeDetailState> emit,
  ) async {
    final result = await _getFileUrl(event.fileId);
    _emitEffect(
      emit,
      result.fold(ChallengeDetailEffect.openUrl, ChallengeDetailEffect.failure),
    );
  }

  static bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _emitEffect(
    Emitter<ChallengeDetailState> emit,
    ChallengeDetailEffect effect,
  ) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
