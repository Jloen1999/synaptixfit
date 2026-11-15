part of 'workout_together_bloc.dart';

@freezed
sealed class WorkoutTogetherEvent with _$WorkoutTogetherEvent {
  const factory WorkoutTogetherEvent.started(String id) =
      WorkoutTogetherStarted;

  /// Volver a leer: consulta de respaldo o, con [live], aviso del canal en
  /// directo (ADR 0047), que se lee siempre.
  const factory WorkoutTogetherEvent.polled({@Default(false) bool live}) =
      WorkoutTogetherPolled;

  const factory WorkoutTogetherEvent.joined() = WorkoutTogetherJoined;

  const factory WorkoutTogetherEvent.declined() = WorkoutTogetherDeclined;

  const factory WorkoutTogetherEvent.left() = WorkoutTogetherLeft;

  /// «Empezar» (o «Seguir entrenando»): mi sesión de siempre.
  const factory WorkoutTogetherEvent.startRequested() =
      WorkoutTogetherStartRequested;
}
