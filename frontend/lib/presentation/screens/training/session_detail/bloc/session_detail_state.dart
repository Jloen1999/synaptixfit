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
  }) = _SessionDetailState;
}
