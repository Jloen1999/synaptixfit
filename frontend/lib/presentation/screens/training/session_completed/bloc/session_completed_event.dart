part of 'session_completed_bloc.dart';

@freezed
sealed class SessionCompletedEvent with _$SessionCompletedEvent {
  const factory SessionCompletedEvent.started({
    required String sessionId,
    FinishSessionResult? result,
  }) = SessionCompletedStarted;

  const factory SessionCompletedEvent.recommendationApplied(
    String recommendationId,
  ) = SessionCompletedRecommendationApplied;

  /// Quita la sugerencia de la lista; el aviso lleva «Deshacer».
  const factory SessionCompletedEvent.recommendationDiscarded(
    String recommendationId,
  ) = SessionCompletedRecommendationDiscarded;

  /// «Deshacer» del aviso: la sugerencia vuelve a la lista.
  const factory SessionCompletedEvent.recommendationRestored(
    Recommendation recommendation,
  ) = SessionCompletedRecommendationRestored;

  /// El aviso se cerró sin deshacer: se descarta en el servidor.
  const factory SessionCompletedEvent.recommendationDiscardConfirmed(
    String recommendationId,
  ) = SessionCompletedRecommendationDiscardConfirmed;

  /// «Guardar como rutina» con el nombre elegido (sesión libre, ADR 0067).
  const factory SessionCompletedEvent.routineSaveRequested(String name) =
      SessionCompletedRoutineSaveRequested;

  /// Publica el resumen en el muro con el texto ya redactado por la página.
  const factory SessionCompletedEvent.shareRequested(String description) =
      SessionCompletedShareRequested;
}
