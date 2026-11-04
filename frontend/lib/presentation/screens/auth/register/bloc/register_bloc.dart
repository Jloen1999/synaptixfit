import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/auth/register_use_case.dart';
import '../../../../../domain/enums/legal_document_kind.dart';
import '../../../../../domain/use_cases/profile/get_legal_document_use_case.dart';

part 'register_bloc.freezed.dart';
part 'register_event.dart';
part 'register_state.dart';

/// Crea la cuenta con correo. La persona ya marcó «He leído y acepto…»: el
/// alta envía la versión vigente de la política y el servidor la guarda en la
/// misma operación (ADR 0034), así no se le vuelve a pedir al entrar.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required this._register, required this._getDocument})
    : super(const RegisterState.idle()) {
    on<RegisterSubmitted>(_onSubmitted);
  }

  final RegisterUseCaseContract _register;
  final GetLegalDocumentUseCaseContract _getDocument;

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(const RegisterState.submitting());
    // La versión del texto enlazado junto a la casilla. Si no se puede leer
    // (sin conexión), la cuenta se crea igual y la aceptación se pide al entrar.
    final document = await _getDocument(
      LegalDocumentKind.privacy,
      language: event.language,
    );
    final result = await _register(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
      acceptedLegalVersion: document.valueOrNull?.version,
    );
    emit(result.fold(RegisterState.success, RegisterState.failure));
  }
}
