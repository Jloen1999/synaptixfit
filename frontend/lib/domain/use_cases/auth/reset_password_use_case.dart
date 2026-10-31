import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/auth_repository_contract.dart';

/// Pone la contraseña nueva con el token del enlace del correo. El servidor
/// cierra todas las sesiones abiertas.
abstract interface class ResetPasswordUseCaseContract {
  Future<AppResult<Unit>> call({
    required String token,
    required String newPassword,
  });
}

class ResetPasswordUseCase implements ResetPasswordUseCaseContract {
  const ResetPasswordUseCase(this._repository);

  final AuthRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({
    required String token,
    required String newPassword,
  }) => _repository.resetPassword(token: token, newPassword: newPassword);
}
