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

  /// Saltar el día que toca (la rutina pasa al siguiente).
  const factory TrainingHomeEvent.daySkipped({
    required String routineId,
    required String dayId,
  }) = TrainingHomeDaySkipped;

  /// «Deshacer» tras saltar el día: vuelve a ser el que toca.
  const factory TrainingHomeEvent.dayUnskipped({
    required String routineId,
    required String dayId,
  }) = TrainingHomeDayUnskipped;

  /// Terminar una sesión abandonada con lo registrado (cuenta en su día).
  const factory TrainingHomeEvent.staleFinished(
    String sessionId, {
    required int minutes,
    required int rpe,
  }) = TrainingHomeStaleFinished;

  /// Descartar una sesión abandonada (se borran sus series).
  const factory TrainingHomeEvent.staleDiscarded(String sessionId) =
      TrainingHomeStaleDiscarded;

  /// Repetir el ciclo de una rutina terminada.
  const factory TrainingHomeEvent.cycleRestarted(String routineId) =
      TrainingHomeCycleRestarted;
}
