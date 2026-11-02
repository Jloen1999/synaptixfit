part of 'open_session_bar_bloc.dart';

@freezed
sealed class OpenSessionBarEvent with _$OpenSessionBarEvent {
  const factory OpenSessionBarEvent.started() = OpenSessionBarStarted;

  const factory OpenSessionBarEvent.refreshed() = OpenSessionBarRefreshed;
}
