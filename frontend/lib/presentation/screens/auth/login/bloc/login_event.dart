part of 'login_bloc.dart';

@freezed
sealed class LoginEvent with _$LoginEvent {
  const factory LoginEvent.submitted({
    required String email,
    required String password,
  }) = LoginSubmitted;

  /// [awaitsWebButton]: en web el flujo lo inicia el botón oficial de Google; el
  /// bloc espera su resultado sin bloquear el formulario de email.
  const factory LoginEvent.googleRequested({
    @Default(false) bool awaitsWebButton,
  }) = LoginGoogleRequested;
}
