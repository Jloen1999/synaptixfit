part of 'reminder_options_bloc.dart';

@freezed
abstract class ReminderOptionsState with _$ReminderOptionsState {
  const factory ReminderOptionsState({
    @Default(true) bool loading,
    @Default(ReminderOptions()) ReminderOptions options,
    AppError? error,

    /// El último cambio no se guardó (se ha vuelto a como estaba).
    AppError? saveError,
  }) = _ReminderOptionsState;
}
