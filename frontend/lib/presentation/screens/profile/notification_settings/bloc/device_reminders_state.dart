part of 'device_reminders_bloc.dart';

@freezed
abstract class DeviceRemindersState with _$DeviceRemindersState {
  const factory DeviceRemindersState({
    @Default(false) bool loaded,

    /// `false` en web: el interruptor no se muestra.
    @Default(false) bool supported,
    @Default(false) bool enabled,
    @Default(false) bool busy,

    /// El sistema no deja mostrar avisos: se quiso activar y negó el permiso,
    /// o se retiró en los ajustes del teléfono. La pantalla muestra una fila
    /// fija que lo explica.
    @Default(false) bool permissionDenied,
    AppError? error,
  }) = _DeviceRemindersState;
}
