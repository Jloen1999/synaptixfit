import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/usage_focus.dart';
import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/account/update_account_use_case.dart';

part 'edit_account_bloc.freezed.dart';
part 'edit_account_event.dart';
part 'edit_account_state.dart';

/// Edición de la cuenta: nombre, avatar, privacidad, modo de uso y fecha de
/// nacimiento. Al guardar, la página pasa la cuenta nueva a `SessionBloc` para
/// que todas las pantallas la vean sin reiniciar.
class EditAccountBloc extends Bloc<EditAccountEvent, EditAccountState> {
  EditAccountBloc({required this._updateAccount})
    : super(const EditAccountState.idle()) {
    on<EditAccountSubmitted>(_onSubmitted);
  }

  final UpdateAccountUseCaseContract _updateAccount;

  Future<void> _onSubmitted(
    EditAccountSubmitted event,
    Emitter<EditAccountState> emit,
  ) async {
    emit(const EditAccountState.submitting());
    final avatar = event.avatarUrl.trim();
    final result = await _updateAccount(
      fullName: event.fullName.trim(),
      // Cadena vacía = quitar el avatar.
      avatarUrl: avatar,
      privacy: event.privacy,
      usageFocus: event.usageFocus,
      birthDate: event.birthDate,
      clearBirthDate: event.clearBirthDate,
    );
    emit(result.fold(EditAccountState.success, EditAccountState.failure));
  }
}
