part of 'material_review_bloc.dart';

@freezed
sealed class MaterialReviewEvent with _$MaterialReviewEvent {
  const factory MaterialReviewEvent.started(String materialId) =
      MaterialReviewStarted;

  /// Autoevaluación SM-2 de 0 (no lo recuerdo) a 5 (perfecto).
  const factory MaterialReviewEvent.qualitySubmitted(int quality) =
      MaterialReviewQualitySubmitted;

  /// Quita el material del repaso (se conservan su historial y el apunte o
  /// archivo de origen).
  const factory MaterialReviewEvent.removeRequested() =
      MaterialReviewRemoveRequested;
}
