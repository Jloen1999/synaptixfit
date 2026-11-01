part of 'session_detail_bloc.dart';

@freezed
sealed class SessionDetailEvent with _$SessionDetailEvent {
  /// Abre la sesión [sessionId]; [entry] llega desde el historial.
  const factory SessionDetailEvent.started(
    String sessionId, {
    SessionHistoryEntry? entry,
  }) = SessionDetailStarted;
}
