part of 'session_detail_bloc.dart';

@freezed
sealed class SessionDetailEvent with _$SessionDetailEvent {
  /// Abre la sesión [sessionId]; [entry] llega desde el historial.
  const factory SessionDetailEvent.started(
    String sessionId, {
    SessionHistoryEntry? entry,
  }) = SessionDetailStarted;

  /// Corregir esfuerzo y duración.
  const factory SessionDetailEvent.correctRequested({
    required int minutes,
    required int rpe,
  }) = SessionDetailCorrectRequested;

  /// «Reabrir y seguir» (solo la terminada hoy).
  const factory SessionDetailEvent.reopenRequested() =
      SessionDetailReopenRequested;

  /// Eliminar (ya confirmado).
  const factory SessionDetailEvent.deleteRequested() =
      SessionDetailDeleteRequested;
}
