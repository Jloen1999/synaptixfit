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

  const factory SessionCompletedEvent.recommendationDiscarded(
    String recommendationId,
  ) = SessionCompletedRecommendationDiscarded;

  /// Publica el resumen en el muro con el texto ya redactado por la página.
  const factory SessionCompletedEvent.shareRequested(String description) =
      SessionCompletedShareRequested;
}
