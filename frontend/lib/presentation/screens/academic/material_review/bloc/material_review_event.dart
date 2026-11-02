part of 'material_review_bloc.dart';

@freezed
sealed class MaterialReviewEvent with _$MaterialReviewEvent {
  const factory MaterialReviewEvent.started(String materialId) =
      MaterialReviewStarted;

  /// Autoevaluación SM-2 de 0 (no lo recuerdo) a 5 (perfecto).
  const factory MaterialReviewEvent.qualitySubmitted(int quality) =
      MaterialReviewQualitySubmitted;

  /// Ya se repasó (recordarlo sin mirar o abrir el material): se puede valorar.
  const factory MaterialReviewEvent.prepared() = MaterialReviewPrepared;

  /// Vuelve de practicar: se pide de nuevo la vista previa, que trae la nota
  /// propuesta con los aciertos.
  const factory MaterialReviewEvent.practiceReturned() =
      MaterialReviewPracticeReturned;

  /// Elige la autoevaluación (se guarda con el botón de abajo).
  const factory MaterialReviewEvent.qualitySelected(int quality) =
      MaterialReviewQualitySelected;

  /// Quita el material del repaso (se conservan su historial y el apunte o
  /// archivo de origen).
  const factory MaterialReviewEvent.removeRequested() =
      MaterialReviewRemoveRequested;
}
