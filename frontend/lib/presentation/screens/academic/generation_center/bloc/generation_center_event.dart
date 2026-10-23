part of 'generation_center_bloc.dart';

@freezed
sealed class GenerationCenterEvent with _$GenerationCenterEvent {
  const factory GenerationCenterEvent.started({String? subjectId}) =
      GenerationCenterStarted;

  const factory GenerationCenterEvent.subjectSelected(String subjectId) =
      GenerationCenterSubjectSelected;

  const factory GenerationCenterEvent.sourceToggled(StudySourceRef source) =
      GenerationCenterSourceToggled;

  const factory GenerationCenterEvent.kindSelected(ArtifactKind kind) =
      GenerationCenterKindSelected;

  /// Genera (o regenera) con las fuentes y el tipo elegidos.
  const factory GenerationCenterEvent.generateRequested() =
      GenerationCenterGenerateRequested;

  const factory GenerationCenterEvent.discarded() = GenerationCenterDiscarded;

  /// Guarda como apunte (resumen y mapa) o como preguntas (flashcards y test).
  const factory GenerationCenterEvent.saveRequested({String? title}) =
      GenerationCenterSaveRequested;
}
