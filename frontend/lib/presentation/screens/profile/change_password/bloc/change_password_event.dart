part of 'change_password_bloc.dart';

@freezed
sealed class ChangePasswordEvent with _$ChangePasswordEvent {
  /// [currentPassword] es `null` cuando la cuenta aún no tiene contraseña.
  const factory ChangePasswordEvent.submitted({
    String? currentPassword,
    required String newPassword,
  }) = ChangePasswordSubmitted;
}
