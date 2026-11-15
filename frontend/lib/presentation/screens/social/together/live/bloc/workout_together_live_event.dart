part of 'workout_together_live_bloc.dart';

@freezed
sealed class WorkoutTogetherLiveEvent with _$WorkoutTogetherLiveEvent {
  /// Con [poll] falso solo se lee una vez (resumen de la sesión terminada).
  const factory WorkoutTogetherLiveEvent.started(
    String sessionId, {
    @Default(true) bool poll,
  }) = WorkoutTogetherLiveStarted;

  const factory WorkoutTogetherLiveEvent.polled() = WorkoutTogetherLivePolled;
}
