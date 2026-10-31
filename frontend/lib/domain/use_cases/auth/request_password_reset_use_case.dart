import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/auth_repository_contract.dart';

/// Pide el correo con el enlace para restablecer la contraseña. El servidor
/// responde igual exista o no la cuenta.
abstract interface class RequestPasswordResetUseCaseContract {
  Future<AppResult<Unit>> call({required String email});
}

class RequestPasswordResetUseCase
    implements RequestPasswordResetUseCaseContract {
  const RequestPasswordResetUseCase(this._repository);

  final AuthRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({required String email}) =>
      _repository.requestPasswordReset(email: email.trim());
}
