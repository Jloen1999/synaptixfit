part of 'workout_together_bloc.dart';

@freezed
sealed class WorkoutTogetherEvent with _$WorkoutTogetherEvent {
  const factory WorkoutTogetherEvent.started(String id) =
      WorkoutTogetherStarted;

  /// Consulta periódica mientras la pantalla está abierta.
  const factory WorkoutTogetherEvent.polled() = WorkoutTogetherPolled;

  const factory WorkoutTogetherEvent.joined() = WorkoutTogetherJoined;

  const factory WorkoutTogetherEvent.declined() = WorkoutTogetherDeclined;

  const factory WorkoutTogetherEvent.left() = WorkoutTogetherLeft;

  /// «Empezar» (o «Seguir entrenando»): mi sesión de siempre.
  const factory WorkoutTogetherEvent.startRequested() =
      WorkoutTogetherStartRequested;
}
