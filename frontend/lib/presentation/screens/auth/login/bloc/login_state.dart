part of 'login_bloc.dart';

@freezed
sealed class LoginState with _$LoginState {
  const factory LoginState.idle() = LoginIdle;

  const factory LoginState.submitting() = LoginSubmitting;

  const factory LoginState.failure(AppError error) = LoginFailure;

  const factory LoginState.success(Account account) = LoginSuccess;
}
