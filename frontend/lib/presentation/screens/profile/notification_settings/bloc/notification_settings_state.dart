part of 'notification_settings_bloc.dart';

enum NotificationSettingsStatus { loading, ready, failure }

@freezed
abstract class NotificationSettingsState with _$NotificationSettingsState {
  const factory NotificationSettingsState({
    @Default(NotificationSettingsStatus.loading)
    NotificationSettingsStatus status,

    /// Preferencias en edición.
    NotificationPreferences? preferences,

    /// Hay cambios sin guardar.
    @Default(false) bool dirty,
    @Default(false) bool saving,
    @Default(false) bool saved,
    AppError? error,
    AppError? actionError,
  }) = _NotificationSettingsState;
}
