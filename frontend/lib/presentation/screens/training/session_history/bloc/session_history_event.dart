part of 'session_history_bloc.dart';

@freezed
sealed class SessionHistoryEvent with _$SessionHistoryEvent {
  const factory SessionHistoryEvent.started() = SessionHistoryStarted;

  const factory SessionHistoryEvent.refreshed() = SessionHistoryRefreshed;

  const factory SessionHistoryEvent.moreRequested() =
      SessionHistoryMoreRequested;

  /// Deshace la finalización (resta la experiencia otorgada).
  const factory SessionHistoryEvent.unmarkRequested(String sessionId) =
      SessionHistoryUnmarkRequested;
}
