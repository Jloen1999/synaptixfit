import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/challenge_difficulty.dart';
import '../../../../../domain/enums/challenge_type.dart';
import '../../../../../domain/enums/milestone_condition.dart';
import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../../domain/models/challenges/challenge_draft.dart';
import '../../../../../domain/models/challenges/challenge_draft_validator.dart';
import '../../../../../domain/models/challenges/challenge_references.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/challenges/create_challenge_use_case.dart';
import '../../../../../domain/use_cases/challenges/get_challenge_use_case.dart';
import '../../../../../domain/use_cases/challenges/list_challenge_subjects_use_case.dart';
import '../../../../../domain/use_cases/challenges/replace_milestones_use_case.dart';

part 'challenge_form_bloc.freezed.dart';
part 'challenge_form_event.dart';
part 'challenge_form_state.dart';

/// Formulario «Nuevo reto» completo (detalles, fechas, visibilidad y tareas) y
/// edición de las tareas de un reto existente.
class ChallengeFormBloc extends Bloc<ChallengeFormEvent, ChallengeFormState> {
  ChallengeFormBloc({
    required this._listSubjects,
    required CreateChallengeUseCaseContract createChallenge,
    required this._getChallenge,
    required ReplaceMilestonesUseCaseContract replaceMilestones,
    required this._getAccount,
    DateTime Function()? now,
  }) : _create = createChallenge,
       _replace = replaceMilestones,
       _now = now ?? DateTime.now,
       super(const ChallengeFormState()) {
    on<ChallengeFormStarted>(_onStarted);
    on<ChallengeFormTitleChanged>(
      (e, emit) => emit(state.copyWith(title: e.title, issue: null)),
    );
    on<ChallengeFormGoalChanged>(
      (e, emit) => emit(state.copyWith(goal: e.goal)),
    );
    on<ChallengeFormTypeChanged>(
      (e, emit) => emit(state.copyWith(type: e.type)),
    );
    on<ChallengeFormSessionTargetChanged>(
      (e, emit) => emit(state.copyWith(sessionTarget: e.target, issue: null)),
    );
    on<ChallengeFormDifficultyChanged>(
      (e, emit) => emit(state.copyWith(difficulty: e.difficulty)),
    );
    on<ChallengeFormVisibilityChanged>(
      (e, emit) => emit(state.copyWith(visibility: e.visibility)),
    );
    on<ChallengeFormStartChanged>(
      (e, emit) => emit(state.copyWith(startAt: e.startAt, issue: null)),
    );
    on<ChallengeFormEndChanged>(
      (e, emit) => emit(state.copyWith(endAt: e.endAt, issue: null)),
    );
    on<ChallengeFormSubjectChanged>(_onSubjectChanged);
    on<ChallengeFormLinkChanged>(
      (e, emit) => emit(
        state.copyWith(
          link: e.link,
          linkLabel: e.link == null ? null : e.label,
        ),
      ),
    );
    on<ChallengeFormMilestoneSaved>(_onMilestoneSaved);
    on<ChallengeFormMilestoneRemoved>(_onMilestoneRemoved);
    on<ChallengeFormMilestoneMoved>(_onMilestoneMoved);
    on<ChallengeFormInOrderToggled>(_onInOrderToggled);
    on<ChallengeFormSubmitted>(_onSubmitted);
  }

  final ListChallengeSubjectsUseCaseContract _listSubjects;
  final CreateChallengeUseCaseContract _create;
  final GetChallengeUseCaseContract _getChallenge;
  final ReplaceMilestonesUseCaseContract _replace;
  final GetAccountUseCaseContract _getAccount;
  final DateTime Function() _now;
  int _keySeed = 0;

  /// Clave local única para una tarea nueva.
  String newMilestoneKey() => 'new-${_keySeed++}';

  Future<void> _onStarted(
    ChallengeFormStarted event,
    Emitter<ChallengeFormState> emit,
  ) async {
    final challengeId = event.challengeId;
    if (challengeId != null) {
      await _startEditing(challengeId, emit);
      return;
    }
    final now = _now();
    final defaultEnd = DateTime(now.year, now.month, now.day + 7, 23, 59);
    emit(
      state.copyWith(
        status: ChallengeFormStatus.ready,
        mode: ChallengeFormMode.create,
        title: event.title ?? '',
        subjectId: event.subjectId,
        subjectName: event.subjectName,
        type: event.type ?? ChallengeType.academic,
        difficulty: event.difficulty ?? ChallengeDifficulty.medium,
        endAt: event.endAt ?? defaultEnd,
        sessionTarget: event.sessionTarget,
      ),
    );
    final subjects = await _listSubjects();
    emit(state.copyWith(subjects: subjects.valueOrNull ?? const []));
  }

  Future<void> _startEditing(
    String challengeId,
    Emitter<ChallengeFormState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ChallengeFormStatus.loading,
        mode: ChallengeFormMode.editMilestones,
        challengeId: challengeId,
        error: null,
      ),
    );
    final result = await _getChallenge(challengeId);
    switch (result) {
      case Success(:final value):
        final items = [
          for (final m in value.milestones)
            MilestoneFormItem(
              key: m.id,
              id: m.id,
              title: m.title,
              difficulty: m.difficulty,
              noteId: m.noteId,
              fileId: m.fileId,
              link: m.link,
              dependsOnKeys: m.dependencies,
              condition: m.condition,
              conditionN: m.conditionN,
              completed: m.completed,
            ),
        ];
        final inOrder = _isChain(items);
        emit(
          state.copyWith(
            status: ChallengeFormStatus.ready,
            title: value.title,
            type: value.type,
            difficulty: value.difficulty,
            visibility: value.visibility,
            startAt: value.startAt,
            endAt: value.endAt,
            subjectId: value.subjectId,
            // En orden, la cadena se rehace al guardar: no se guardan claves.
            milestones: inOrder
                ? [for (final m in items) m.copyWith(dependsOnKeys: const [])]
                : items,
            inOrder: inOrder,
            tracksTrainingSessions: value.tracksTrainingSessions,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(status: ChallengeFormStatus.failure, error: error));
    }
  }

  void _onSubjectChanged(
    ChallengeFormSubjectChanged event,
    Emitter<ChallengeFormState> emit,
  ) {
    String? name;
    for (final s in state.subjects) {
      if (s.id == event.subjectId) name = s.name;
    }
    emit(
      state.copyWith(
        subjectId: event.subjectId,
        subjectName: name,
        type: event.subjectId != null ? ChallengeType.academic : state.type,
      ),
    );
  }

  void _onMilestoneSaved(
    ChallengeFormMilestoneSaved event,
    Emitter<ChallengeFormState> emit,
  ) {
    final item = event.item;
    final index = state.milestones.indexWhere((m) => m.key == item.key);
    if (index < 0 && !state.canAddMilestone) {
      emit(state.copyWith(issue: ChallengeDraftIssue.tooManyMilestones));
      return;
    }
    final list = [...state.milestones];
    if (index < 0) {
      list.add(item);
    } else {
      list[index] = item;
    }
    emit(state.copyWith(milestones: list, issue: null));
  }

  void _onMilestoneRemoved(
    ChallengeFormMilestoneRemoved event,
    Emitter<ChallengeFormState> emit,
  ) {
    final list = [
      for (final m in state.milestones)
        if (m.key != event.key) _withoutDependency(m, event.key),
    ];
    emit(state.copyWith(milestones: list, issue: null));
  }

  /// Quita la dependencia [key] y ajusta la condición «X de Y» si hace falta.
  MilestoneFormItem _withoutDependency(MilestoneFormItem m, String key) {
    if (!m.dependsOnKeys.contains(key)) return m;
    final deps = m.dependsOnKeys.where((k) => k != key).toList();
    return m.copyWith(
      dependsOnKeys: deps,
      conditionN: deps.isEmpty ? 1 : m.conditionN.clamp(1, deps.length),
      condition: deps.isEmpty ? MilestoneCondition.all : m.condition,
    );
  }

  void _onMilestoneMoved(
    ChallengeFormMilestoneMoved event,
    Emitter<ChallengeFormState> emit,
  ) {
    final list = [...state.milestones];
    final from = list.indexWhere((m) => m.key == event.key);
    final to = from + event.delta;
    if (from < 0 || to < 0 || to >= list.length) return;
    final item = list.removeAt(from);
    list.insert(to, item);
    emit(state.copyWith(milestones: list));
  }

  void _onInOrderToggled(
    ChallengeFormInOrderToggled event,
    Emitter<ChallengeFormState> emit,
  ) {
    if (event.inOrder == state.inOrder) return;
    emit(
      state.copyWith(
        inOrder: event.inOrder,
        issue: null,
        milestones: [
          for (final m in state.milestones)
            m.copyWith(
              dependsOnKeys: const [],
              condition: MilestoneCondition.all,
              conditionN: 1,
            ),
        ],
      ),
    );
  }

  /// ¿Cada tarea depende solo de la anterior (y la primera de ninguna)?
  static bool _isChain(List<MilestoneFormItem> items) {
    if (items.length < 2 || items.first.dependsOnKeys.isNotEmpty) return false;
    for (var i = 1; i < items.length; i++) {
      final deps = items[i].dependsOnKeys;
      if (deps.length != 1 || deps.first != items[i - 1].key) return false;
    }
    return true;
  }

  /// Convierte las tareas del formulario en borradores con dependencias por posición.
  List<MilestoneDraft> buildMilestoneDrafts() {
    final index = {
      for (var i = 0; i < state.milestones.length; i++)
        state.milestones[i].key: i,
    };
    if (state.inOrder) {
      // «En orden»: cada tarea depende de la anterior (AND).
      return [
        for (var i = 0; i < state.milestones.length; i++)
          MilestoneDraft(
            id: state.milestones[i].id,
            title: state.milestones[i].title,
            difficulty: state.milestones[i].difficulty,
            noteId: state.milestones[i].noteId,
            fileId: state.milestones[i].fileId,
            link: state.milestones[i].link,
            dependsOn: i == 0 ? const [] : [i - 1],
          ),
      ];
    }
    return [
      for (final m in state.milestones)
        MilestoneDraft(
          id: m.id,
          title: m.title,
          difficulty: m.difficulty,
          noteId: m.noteId,
          fileId: m.fileId,
          link: m.link,
          dependsOn: [for (final k in m.dependsOnKeys) ?index[k]],
          condition: m.dependsOnKeys.isEmpty
              ? MilestoneCondition.all
              : m.condition,
          conditionN: m.condition == MilestoneCondition.xOfY
              ? m.conditionN
              : null,
        ),
    ];
  }

  Future<void> _onSubmitted(
    ChallengeFormSubmitted event,
    Emitter<ChallengeFormState> emit,
  ) async {
    if (state.status != ChallengeFormStatus.ready) return;
    final drafts = buildMilestoneDrafts();
    if (state.mode == ChallengeFormMode.editMilestones) {
      await _submitMilestones(drafts, emit);
      return;
    }
    final draft = ChallengeDraft(
      title: state.title,
      type: state.type,
      goal: state.goal,
      visibility: state.visibility,
      difficulty: state.difficulty,
      startAt: state.startAt,
      endAt: state.endAt ?? _now().add(const Duration(days: 7)),
      subjectId: state.subjectId,
      link: state.link,
      milestones: drafts,
      sessionTarget: state.showsSessionTarget ? state.sessionTarget : null,
    );
    final issue = ChallengeDraftValidator.validate(draft);
    if (issue != null) {
      emit(state.copyWith(issue: issue));
      return;
    }
    emit(state.copyWith(status: ChallengeFormStatus.saving, issue: null));
    final result = await _create(draft);
    switch (result) {
      case Success(:final value):
        emit(state.copyWith(status: ChallengeFormStatus.ready));
        _emitEffect(emit, ChallengeFormEffect.saved(challengeId: value.id));
      case Failure(:final error):
        emit(state.copyWith(status: ChallengeFormStatus.ready));
        _emitEffect(emit, ChallengeFormEffect.failure(error));
    }
  }

  Future<void> _submitMilestones(
    List<MilestoneDraft> drafts,
    Emitter<ChallengeFormState> emit,
  ) async {
    final challengeId = state.challengeId;
    if (challengeId == null) return;
    final issue = ChallengeDraftValidator.validateMilestones(drafts);
    if (issue != null) {
      emit(state.copyWith(issue: issue));
      return;
    }
    emit(state.copyWith(status: ChallengeFormStatus.saving, issue: null));
    final result = await _replace(challengeId, drafts);
    switch (result) {
      case Success(:final value):
        final account = value.xpDelta != 0
            ? (await _getAccount()).valueOrNull
            : null;
        emit(state.copyWith(status: ChallengeFormStatus.ready));
        _emitEffect(
          emit,
          ChallengeFormEffect.saved(
            challengeId: challengeId,
            xpDelta: value.xpDelta,
            account: account,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(status: ChallengeFormStatus.ready));
        _emitEffect(emit, ChallengeFormEffect.failure(error));
    }
  }

  void _emitEffect(
    Emitter<ChallengeFormState> emit,
    ChallengeFormEffect effect,
  ) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
