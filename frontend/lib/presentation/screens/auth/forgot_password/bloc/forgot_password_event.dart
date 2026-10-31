part of 'forgot_password_bloc.dart';

@freezed
sealed class ForgotPasswordEvent with _$ForgotPasswordEvent {
  const factory ForgotPasswordEvent.submitted(String email) =
      ForgotPasswordSubmitted;
}
