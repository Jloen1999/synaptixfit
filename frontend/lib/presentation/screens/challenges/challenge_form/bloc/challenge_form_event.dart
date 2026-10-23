part of 'challenge_form_bloc.dart';

@freezed
sealed class ChallengeFormEvent with _$ChallengeFormEvent {
  /// Abre el formulario. Con [challengeId] edita las tareas de ese reto;
  /// si no, crea uno nuevo con los valores iniciales recibidos.
  const factory ChallengeFormEvent.started({
    String? challengeId,
    String? title,
    String? subjectId,
    String? subjectName,
    ChallengeType? type,
    ChallengeDifficulty? difficulty,
    DateTime? endAt,
    int? sessionTarget,
  }) = ChallengeFormStarted;

  const factory ChallengeFormEvent.titleChanged(String title) =
      ChallengeFormTitleChanged;

  const factory ChallengeFormEvent.goalChanged(String goal) =
      ChallengeFormGoalChanged;

  const factory ChallengeFormEvent.typeChanged(ChallengeType type) =
      ChallengeFormTypeChanged;

  /// `null` si el campo queda vacío.
  const factory ChallengeFormEvent.sessionTargetChanged(int? target) =
      ChallengeFormSessionTargetChanged;

  const factory ChallengeFormEvent.difficultyChanged(
    ChallengeDifficulty difficulty,
  ) = ChallengeFormDifficultyChanged;

  const factory ChallengeFormEvent.visibilityChanged(Visibility visibility) =
      ChallengeFormVisibilityChanged;

  const factory ChallengeFormEvent.startChanged(DateTime? startAt) =
      ChallengeFormStartChanged;

  const factory ChallengeFormEvent.endChanged(DateTime endAt) =
      ChallengeFormEndChanged;

  const factory ChallengeFormEvent.subjectChanged(String? subjectId) =
      ChallengeFormSubjectChanged;

  const factory ChallengeFormEvent.linkChanged({
    ChallengeLink? link,
    String? label,
  }) = ChallengeFormLinkChanged;

  /// Añade (clave nueva) o sustituye (clave existente) una tarea.
  const factory ChallengeFormEvent.milestoneSaved(MilestoneFormItem item) =
      ChallengeFormMilestoneSaved;

  const factory ChallengeFormEvent.milestoneRemoved(String key) =
      ChallengeFormMilestoneRemoved;

  /// Mueve una tarea [delta] posiciones (−1 sube, +1 baja).
  const factory ChallengeFormEvent.milestoneMoved(String key, int delta) =
      ChallengeFormMilestoneMoved;

  const factory ChallengeFormEvent.manualWeightsToggled(bool manual) =
      ChallengeFormManualWeightsToggled;

  const factory ChallengeFormEvent.weightChanged(String key, double? weight) =
      ChallengeFormWeightChanged;

  /// Reparte 100 a partes iguales entre las tareas.
  const factory ChallengeFormEvent.weightsDistributed() =
      ChallengeFormWeightsDistributed;

  const factory ChallengeFormEvent.submitted() = ChallengeFormSubmitted;
}
