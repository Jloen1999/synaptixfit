import '../../models/admin/erasure_report.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Elimina definitivamente a un usuario.
abstract interface class DeleteAdminUserUseCaseContract {
  Future<AppResult<ErasureReport>> call(String userId);
}

class DeleteAdminUserUseCase implements DeleteAdminUserUseCaseContract {
  const DeleteAdminUserUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<ErasureReport>> call(String userId) =>
      _repository.deleteUser(userId);
}
