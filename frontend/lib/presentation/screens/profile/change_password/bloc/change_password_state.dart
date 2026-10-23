part of 'change_password_bloc.dart';

@freezed
sealed class ChangePasswordState with _$ChangePasswordState {
  const factory ChangePasswordState.idle() = ChangePasswordIdle;

  const factory ChangePasswordState.submitting() = ChangePasswordSubmitting;

  /// [account] es la cuenta refrescada (puede faltar si falló el refresco).
  const factory ChangePasswordState.success(Account? account) =
      ChangePasswordSuccess;

  const factory ChangePasswordState.failure(AppError error) =
      ChangePasswordFailure;
}
