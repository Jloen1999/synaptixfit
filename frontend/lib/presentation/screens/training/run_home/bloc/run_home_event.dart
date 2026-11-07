part of 'run_home_bloc.dart';

@freezed
sealed class RunHomeEvent with _$RunHomeEvent {
  const factory RunHomeEvent.started() = RunHomeStarted;

  const factory RunHomeEvent.refreshed() = RunHomeRefreshed;

  const factory RunHomeEvent.workoutDeleted(String workoutId) =
      RunHomeWorkoutDeleted;

  /// «Poner en el calendario» a esa hora.
  const factory RunHomeEvent.workoutScheduled(
    String workoutId,
    DateTime start,
  ) = RunHomeWorkoutScheduled;

  /// «Compartir» la semana: imagen solo con las cifras (nunca el mapa).
  const factory RunHomeEvent.shared(Uint8List png, String text) = RunHomeShared;
}
