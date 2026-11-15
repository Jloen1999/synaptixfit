part of 'workout_together_live_bloc.dart';

@freezed
sealed class WorkoutTogetherLiveEvent with _$WorkoutTogetherLiveEvent {
  /// Con [poll] falso solo se lee una vez (resumen de la sesión terminada).
  const factory WorkoutTogetherLiveEvent.started(
    String sessionId, {
    @Default(true) bool poll,
  }) = WorkoutTogetherLiveStarted;

  /// Volver a leer. Con [live] lo pide el canal en directo (ADR 0047) y se lee
  /// siempre; sin él es la consulta de respaldo, que con el canal conectado se
  /// salta si se leyó hace poco.
  const factory WorkoutTogetherLiveEvent.polled({@Default(false) bool live}) =
      WorkoutTogetherLivePolled;
}
