part of 'reminder_options_bloc.dart';

@freezed
sealed class ReminderOptionsEvent with _$ReminderOptionsEvent {
  const factory ReminderOptionsEvent.started() = ReminderOptionsStarted;

  const factory ReminderOptionsEvent.changed(ReminderOptions options) =
      ReminderOptionsChanged;
}
