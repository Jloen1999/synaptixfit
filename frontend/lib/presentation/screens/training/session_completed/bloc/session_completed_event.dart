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
}
