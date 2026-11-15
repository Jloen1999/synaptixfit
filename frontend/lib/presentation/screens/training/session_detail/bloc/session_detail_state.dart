part of 'session_detail_bloc.dart';

enum SessionDetailStatus { loading, ready, failure }

@freezed
abstract class SessionDetailState with _$SessionDetailState {
  const factory SessionDetailState({
    @Default(SessionDetailStatus.loading) SessionDetailStatus status,
    SessionHistoryEntry? entry,

    /// Ejercicios de la rutina por id de ejercicio planificado.
    @Default(<String, PlannedExercise>{})
    Map<String, PlannedExercise> exercises,
    SessionHighlights? highlights,
    AppError? error,

    /// Una acción va camino del servidor: los botones esperan.
    @Default(false) bool busy,

    /// Se eliminó: la pantalla se cierra.
    @Default(false) bool deleted,

    /// Se reabrió: se entra en esa sesión en vivo (efecto de un solo uso).
    String? reopened,

    /// Aviso, error o cuenta al día (efecto de un solo uso).
    TrainingEffect? effect,
  }) = _SessionDetailState;
}
