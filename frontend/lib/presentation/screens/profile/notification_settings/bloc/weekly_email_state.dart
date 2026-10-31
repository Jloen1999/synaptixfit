part of 'weekly_email_bloc.dart';

@freezed
abstract class WeeklyEmailState with _$WeeklyEmailState {
  const factory WeeklyEmailState({
    /// Null mientras carga o si no se pudo leer.
    WeeklyEmailStatus? status,
    @Default(false) bool busy,

    /// Fallo al leer el estado: la sección muestra el error y «Reintentar».
    AppError? loadError,

    /// Fallo al activar o desactivar (aviso; el estado anterior se mantiene).
    AppError? error,
  }) = _WeeklyEmailState;
}
