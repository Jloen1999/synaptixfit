part of 'training_home_bloc.dart';

@freezed
sealed class TrainingHomeEvent with _$TrainingHomeEvent {
  const factory TrainingHomeEvent.started() = TrainingHomeStarted;

  /// Pull-to-refresh o vuelta a la pestaña: recarga sin esqueleto.
  const factory TrainingHomeEvent.refreshed() = TrainingHomeRefreshed;

  const factory TrainingHomeEvent.recommendationApplied(
    String recommendationId,
  ) = TrainingHomeRecommendationApplied;

  const factory TrainingHomeEvent.recommendationDiscarded(
    String recommendationId,
  ) = TrainingHomeRecommendationDiscarded;

  /// Empezar una sesión de un día (o libre si ambos son nulos).
  const factory TrainingHomeEvent.sessionStarted({
    String? routineId,
    String? dayId,
  }) = TrainingHomeSessionStarted;
}
