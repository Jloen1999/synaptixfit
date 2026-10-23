part of 'reminders_bloc.dart';

@freezed
abstract class RemindersState with _$RemindersState {
  const factory RemindersState({
    /// Aviso tocado pendiente de navegar a su pantalla.
    ReminderKind? openRequest,

    /// Avisos programados en la última sincronización correcta.
    int? scheduled,
  }) = _RemindersState;
}
