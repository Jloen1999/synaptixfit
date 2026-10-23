import '../../models/admin/erasure_report.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Vacía el contenido de un usuario conservando la cuenta.
abstract interface class WipeAdminUserUseCaseContract {
  Future<AppResult<ErasureReport>> call(String userId);
}

class WipeAdminUserUseCase implements WipeAdminUserUseCaseContract {
  const WipeAdminUserUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<ErasureReport>> call(String userId) =>
      _repository.wipeUser(userId);
}
