part of 'notification_settings_bloc.dart';

@freezed
sealed class NotificationSettingsEvent with _$NotificationSettingsEvent {
  const factory NotificationSettingsEvent.started() =
      NotificationSettingsStarted;

  const factory NotificationSettingsEvent.categoryToggled(
    NotificationCategory category,
  ) = NotificationSettingsCategoryToggled;

  const factory NotificationSettingsEvent.quietHoursChanged({
    required ClockTime start,
    required ClockTime end,
  }) = NotificationSettingsQuietHoursChanged;

  /// Desactiva las horas de silencio.
  const factory NotificationSettingsEvent.quietHoursCleared() =
      NotificationSettingsQuietHoursCleared;

  const factory NotificationSettingsEvent.dailyLimitChanged(int limit) =
      NotificationSettingsDailyLimitChanged;

  const factory NotificationSettingsEvent.modeChanged(NotificationMode mode) =
      NotificationSettingsModeChanged;

  const factory NotificationSettingsEvent.saveRequested() =
      NotificationSettingsSaveRequested;
}
