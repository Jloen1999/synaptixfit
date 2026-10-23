import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/account/change_password_use_case.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';

part 'change_password_bloc.freezed.dart';
part 'change_password_event.dart';
part 'change_password_state.dart';

/// Cambiar la contraseña, o crearla si la cuenta es solo de Google.
class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  ChangePasswordBloc({required this._changePassword, required this._getAccount})
    : super(const ChangePasswordState.idle()) {
    on<ChangePasswordSubmitted>(_onSubmitted);
  }

  final ChangePasswordUseCaseContract _changePassword;
  final GetAccountUseCaseContract _getAccount;

  Future<void> _onSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(const ChangePasswordState.submitting());
    final current = event.currentPassword;
    final result = await _changePassword(
      currentPassword: current == null || current.isEmpty ? null : current,
      newPassword: event.newPassword,
    );
    if (result.errorOrNull case final error?) {
      emit(ChangePasswordState.failure(error));
      return;
    }
    // La cuenta pasa a tener contraseña: se refresca para la sesión.
    final account = await _getAccount();
    emit(ChangePasswordState.success(account.valueOrNull));
  }
}
