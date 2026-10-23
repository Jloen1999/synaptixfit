part of 'register_bloc.dart';

@freezed
sealed class RegisterEvent with _$RegisterEvent {
  const factory RegisterEvent.submitted({
    required String fullName,
    required String email,
    required String password,
  }) = RegisterSubmitted;
}
