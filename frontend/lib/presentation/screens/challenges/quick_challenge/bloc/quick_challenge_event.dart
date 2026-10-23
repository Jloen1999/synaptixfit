part of 'quick_challenge_bloc.dart';

@freezed
sealed class QuickChallengeEvent with _$QuickChallengeEvent {
  /// Carga las asignaturas para el selector.
  const factory QuickChallengeEvent.started() = QuickChallengeStarted;

  /// Crea el reto o, con [editing], guarda sus datos básicos.
  const factory QuickChallengeEvent.submitted({
    Challenge? editing,
    required String title,
    required ChallengeType type,
    required ChallengeDifficulty difficulty,
    required DateTime endAt,
    String? subjectId,

    /// Objetivo de sesiones de entrenamiento; `null` si el campo queda vacío.
    int? sessionTarget,
  }) = QuickChallengeSubmitted;
}
