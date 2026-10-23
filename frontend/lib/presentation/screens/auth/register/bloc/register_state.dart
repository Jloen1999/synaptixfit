part of 'register_bloc.dart';

@freezed
sealed class RegisterState with _$RegisterState {
  const factory RegisterState.idle() = RegisterIdle;

  const factory RegisterState.submitting() = RegisterSubmitting;

  const factory RegisterState.failure(AppError error) = RegisterFailure;

  const factory RegisterState.success(Account account) = RegisterSuccess;
}
