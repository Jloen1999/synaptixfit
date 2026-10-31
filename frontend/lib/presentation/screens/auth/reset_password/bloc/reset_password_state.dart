part of 'reset_password_bloc.dart';

@freezed
sealed class ResetPasswordState with _$ResetPasswordState {
  const factory ResetPasswordState.idle() = ResetPasswordIdle;

  const factory ResetPasswordState.submitting() = ResetPasswordSubmitting;

  /// Contraseña cambiada: todas las sesiones se cerraron.
  const factory ResetPasswordState.done() = ResetPasswordDone;

  const factory ResetPasswordState.failure(AppError error) =
      ResetPasswordFailure;
}
