part of 'device_reminders_bloc.dart';

@freezed
sealed class DeviceRemindersEvent with _$DeviceRemindersEvent {
  const factory DeviceRemindersEvent.started() = DeviceRemindersStarted;

  /// Activar (pide permiso al sistema) o desactivar los avisos del teléfono.
  const factory DeviceRemindersEvent.toggled(bool enabled) =
      DeviceRemindersToggled;
}
