import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Exporta todos los datos de un usuario como JSON.
abstract interface class ExportAdminUserDataUseCaseContract {
  Future<AppResult<String>> call(String userId);
}

class ExportAdminUserDataUseCase implements ExportAdminUserDataUseCaseContract {
  const ExportAdminUserDataUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<String>> call(String userId) =>
      _repository.exportUserData(userId);
}
