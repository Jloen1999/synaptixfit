import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/auth/login_use_case.dart';
import '../../../../../domain/use_cases/auth/login_with_google_use_case.dart';

part 'login_bloc.freezed.dart';
part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this._login, required this._loginWithGoogle})
    : super(const LoginState.idle()) {
    on<LoginSubmitted>(_onSubmitted);
    on<LoginGoogleRequested>(_onGoogle);
  }

  final LoginUseCaseContract _login;
  final LoginWithGoogleUseCaseContract _loginWithGoogle;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginState.submitting());
    final result = await _login(email: event.email, password: event.password);
    emit(result.fold(LoginState.success, LoginState.failure));
  }

  Future<void> _onGoogle(
    LoginGoogleRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (!event.awaitsWebButton) emit(const LoginState.submitting());
    final result = await _loginWithGoogle();
    emit(
      result.fold(
        LoginState.success,
        (error) => error == const AppError.business('GOOGLE_SIGN_IN_CANCELLED')
            ? const LoginState.idle()
            : LoginState.failure(error),
      ),
    );
    // Si Google dio el token pero el backend lo rechazó, el botón web vuelve a
    // quedar a la escucha. Los fallos del propio Google no se reintentan (bucle).
    if (event.awaitsWebButton &&
        !result.isSuccess &&
        !_isGoogleSideError(result.errorOrNull)) {
      add(event);
    }
  }

  static bool _isGoogleSideError(AppError? error) =>
      error is BusinessError && error.code.startsWith('GOOGLE_SIGN_IN_');
}
