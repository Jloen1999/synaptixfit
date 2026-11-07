part of 'reminder_options_bloc.dart';

/// Cuatro estados de la sección: cargando ([loading]), error al cargar
/// ([error], con reintento), guardando ([saving]) y guardado ([saved]).
@freezed
abstract class ReminderOptionsState with _$ReminderOptionsState {
  const factory ReminderOptionsState({
    @Default(true) bool loading,
    @Default(ReminderOptions()) ReminderOptions options,
    AppError? error,

    /// Hay un cambio camino del servidor.
    @Default(false) bool saving,

    /// El último cambio ya está guardado en el servidor.
    @Default(false) bool saved,

    /// El último cambio no se guardó (se ha vuelto a como estaba).
    AppError? saveError,

    /// Lo que no se pudo guardar, para «Reintentar» desde el aviso.
    ReminderOptions? unsaved,
  }) = _ReminderOptionsState;
}
