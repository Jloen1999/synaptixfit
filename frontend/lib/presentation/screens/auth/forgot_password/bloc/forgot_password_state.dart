part of 'forgot_password_bloc.dart';

@freezed
abstract class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState({
    @Default(false) bool submitting,

    /// Correo al que se pidió el enlace; con valor se muestra «Revisa tu correo».
    String? sentTo,

    /// Veces que se ha vuelto a pedir desde «Revisa tu correo».
    @Default(0) int resends,
    AppError? error,
  }) = _ForgotPasswordState;
}
