import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/challenge_difficulty.dart';
import '../../../../../domain/enums/challenge_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../../domain/models/challenges/challenge_draft.dart';
import '../../../../../domain/models/challenges/challenge_references.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/use_cases/challenges/create_challenge_use_case.dart';
import '../../../../../domain/use_cases/challenges/list_challenge_subjects_use_case.dart';
import '../../../../../domain/use_cases/challenges/update_challenge_use_case.dart';

part 'quick_challenge_bloc.freezed.dart';
part 'quick_challenge_event.dart';
part 'quick_challenge_state.dart';

/// Hoja de creación rápida de un reto (o edición de sus datos básicos).
class QuickChallengeBloc
    extends Bloc<QuickChallengeEvent, QuickChallengeState> {
  QuickChallengeBloc({
    required this._listSubjects,
    required CreateChallengeUseCaseContract createChallenge,
    required UpdateChallengeUseCaseContract updateChallenge,
  }) : _create = createChallenge,
       _update = updateChallenge,
       super(const QuickChallengeState()) {
    on<QuickChallengeStarted>(_onStarted);
    on<QuickChallengeSubmitted>(_onSubmitted);
  }

  final ListChallengeSubjectsUseCaseContract _listSubjects;
  final CreateChallengeUseCaseContract _create;
  final UpdateChallengeUseCaseContract _update;

  Future<void> _onStarted(
    QuickChallengeStarted event,
    Emitter<QuickChallengeState> emit,
  ) async {
    final result = await _listSubjects();
    emit(
      state.copyWith(
        status: QuickChallengeStatus.ready,
        subjects: result.valueOrNull ?? const [],
      ),
    );
  }

  Future<void> _onSubmitted(
    QuickChallengeSubmitted event,
    Emitter<QuickChallengeState> emit,
  ) async {
    if (state.status == QuickChallengeStatus.saving) return;
    emit(state.copyWith(status: QuickChallengeStatus.saving, error: null));
    final editing = event.editing;
    final AppResult<Challenge> result;
    if (editing == null) {
      result = await _create(
        ChallengeDraft(
          title: event.title,
          type: event.type,
          difficulty: event.difficulty,
          endAt: event.endAt,
          subjectId: event.subjectId,
          sessionTarget: event.type == ChallengeType.fitness
              ? event.sessionTarget
              : null,
        ),
      );
    } else {
      // La hoja ya envía null si el campo no se muestra (con tareas).
      final target = event.type == ChallengeType.fitness
          ? event.sessionTarget
          : null;
      result = await _update(
        editing.id,
        ChallengeChanges(
          title: event.title,
          type: event.type,
          difficulty: event.difficulty,
          endAt: event.endAt,
          subjectId: event.subjectId,
          clearSubject: event.subjectId == null && editing.subjectId != null,
          sessionTarget: target,
          clearSessionTarget:
              target == null && _dropsSessionTarget(editing, event),
        ),
      );
    }
    emit(
      result.fold(
        (challenge) => state.copyWith(
          status: QuickChallengeStatus.saved,
          saved: challenge,
        ),
        (error) =>
            state.copyWith(status: QuickChallengeStatus.ready, error: error),
      ),
    );
  }

  /// Hay que quitar el objetivo si existía y el usuario pasó el reto a
  /// académico (el servidor lo rechaza fuera de fitness) o vació el campo de
  /// un reto que, según el servidor, cuenta sesiones. Si no las cuenta (tiene
  /// tareas), el campo no se mostró y el objetivo se conserva.
  static bool _dropsSessionTarget(
    Challenge editing,
    QuickChallengeSubmitted e,
  ) {
    if (editing.sessionTarget == null) return false;
    return e.type != ChallengeType.fitness || editing.tracksTrainingSessions;
  }
}
