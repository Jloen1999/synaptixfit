part of 'workout_together_live_bloc.dart';

@freezed
abstract class WorkoutTogetherLiveState with _$WorkoutTogetherLiveState {
  const factory WorkoutTogetherLiveState({
    String? sessionId,
    @Default(false) bool loaded,

    /// Nulo si la sesión no es de entrenar juntos.
    WorkoutTogether? workout,
  }) = _WorkoutTogetherLiveState;
}
