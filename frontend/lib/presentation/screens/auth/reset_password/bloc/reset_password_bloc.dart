import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/use_cases/auth/reset_password_use_case.dart';

part 'reset_password_bloc.freezed.dart';
part 'reset_password_event.dart';
part 'reset_password_state.dart';

/// Contraseña nueva con el enlace del correo (`/reset-password?token=…`).
class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  ResetPasswordBloc({required this._resetPassword})
    : super(const ResetPasswordState.idle()) {
    on<ResetPasswordSubmitted>(_onSubmitted);
  }

  final ResetPasswordUseCaseContract _resetPassword;

  Future<void> _onSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (state is ResetPasswordSubmitting) return;
    emit(const ResetPasswordState.submitting());
    final result = await _resetPassword(
      token: event.token,
      newPassword: event.newPassword,
    );
    emit(
      result.fold(
        (_) => const ResetPasswordState.done(),
        ResetPasswordState.failure,
      ),
    );
  }
}
