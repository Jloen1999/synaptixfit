part of 'session_history_bloc.dart';

@freezed
sealed class SessionHistoryEvent with _$SessionHistoryEvent {
  const factory SessionHistoryEvent.started() = SessionHistoryStarted;

  const factory SessionHistoryEvent.refreshed() = SessionHistoryRefreshed;

  const factory SessionHistoryEvent.moreRequested() =
      SessionHistoryMoreRequested;

  /// Deshace la finalización (solo el mismo día; resta la experiencia).
  const factory SessionHistoryEvent.unmarkRequested(String sessionId) =
      SessionHistoryUnmarkRequested;

  /// Corrige el RPE y la duración de una sesión de otro día.
  const factory SessionHistoryEvent.correctRequested(
    String sessionId, {
    required int minutes,
    required int rpe,
  }) = SessionHistoryCorrectRequested;

  /// Elimina una sesión terminada (resta su XP y retira su carga).
  const factory SessionHistoryEvent.deleteRequested(String sessionId) =
      SessionHistoryDeleteRequested;

  /// Termina con lo registrado una sesión abandonada (cuenta en su día).
  const factory SessionHistoryEvent.staleFinished(
    String sessionId, {
    required int minutes,
    required int rpe,
  }) = SessionHistoryStaleFinished;

  /// Descarta una sesión sin terminar.
  const factory SessionHistoryEvent.staleDiscarded(String sessionId) =
      SessionHistoryStaleDiscarded;
}
