part of 'reminders_bloc.dart';

@freezed
abstract class RemindersState with _$RemindersState {
  const factory RemindersState({
    /// Aviso tocado pendiente de navegar a su pantalla.
    OpenedReminder? openRequest,

    /// Avisos programados en la última sincronización correcta.
    int? scheduled,

    /// Hay que preguntar si se activan los recordatorios (una sola vez).
    @Default(false) bool offerReminders,

    /// Se aceptó pero el sistema negó el permiso: hay que decir cómo activarlo.
    @Default(0) int permissionDeniedCount,
  }) = _RemindersState;
}
