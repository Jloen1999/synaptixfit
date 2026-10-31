import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/use_cases/auth/request_password_reset_use_case.dart';

part 'forgot_password_bloc.freezed.dart';
part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

/// «¿Has olvidado tu contraseña?»: pide el correo con el enlace. El resultado
/// es el mismo exista o no la cuenta (lo decide el servidor). Volver a pedirlo
/// no saca de «Revisa tu correo».
class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc({required this._requestReset})
    : super(const ForgotPasswordState()) {
    on<ForgotPasswordSubmitted>(_onSubmitted);
  }

  final RequestPasswordResetUseCaseContract _requestReset;

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (state.submitting) return;
    final email = event.email.trim();
    final resending = state.sentTo != null;
    emit(state.copyWith(submitting: true, error: null));
    final result = await _requestReset(email: email);
    emit(
      result.fold(
        (_) => state.copyWith(
          submitting: false,
          sentTo: email,
          resends: resending ? state.resends + 1 : 0,
        ),
        (error) => state.copyWith(submitting: false, error: error),
      ),
    );
  }
}
