part of 'run_home_bloc.dart';

@freezed
sealed class RunHomeEvent with _$RunHomeEvent {
  const factory RunHomeEvent.started() = RunHomeStarted;

  const factory RunHomeEvent.refreshed() = RunHomeRefreshed;

  /// Deslizado: se quita de la lista al momento y se elimina al cerrarse el
  /// aviso con «Deshacer» ([workoutDeleteCommitted]).
  const factory RunHomeEvent.workoutDeleted(String workoutId) =
      RunHomeWorkoutDeleted;

  /// «Deshacer» del aviso: vuelve a la lista sin tocar el servidor.
  const factory RunHomeEvent.workoutDeleteUndone(String workoutId) =
      RunHomeWorkoutDeleteUndone;

  /// El aviso se cerró sin «Deshacer»: se elimina de verdad.
  const factory RunHomeEvent.workoutDeleteCommitted(String workoutId) =
      RunHomeWorkoutDeleteCommitted;

  /// «Poner en el calendario» a esa hora.
  const factory RunHomeEvent.workoutScheduled(
    String workoutId,
    DateTime start,
  ) = RunHomeWorkoutScheduled;

  /// «Compartir» la semana: imagen solo con las cifras (nunca el mapa).
  const factory RunHomeEvent.shared(Uint8List png, String text) = RunHomeShared;

  /// «Abrir los ajustes de la app» de la ayuda de batería (para quitar el
  /// ahorro de batería que corta el GPS).
  const factory RunHomeEvent.batterySettingsOpened() =
      RunHomeBatterySettingsOpened;
}
