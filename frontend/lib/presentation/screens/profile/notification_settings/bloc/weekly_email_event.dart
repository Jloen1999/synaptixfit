part of 'weekly_email_bloc.dart';

@freezed
sealed class WeeklyEmailEvent with _$WeeklyEmailEvent {
  const factory WeeklyEmailEvent.started() = WeeklyEmailStarted;

  const factory WeeklyEmailEvent.toggled(bool enabled) = WeeklyEmailToggled;
}
