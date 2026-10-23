import '../../models/admin/erasure_report.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Anonimiza la cuenta de un usuario (RGPD).
abstract interface class AnonymizeAdminUserUseCaseContract {
  Future<AppResult<ErasureReport>> call(String userId);
}

class AnonymizeAdminUserUseCase implements AnonymizeAdminUserUseCaseContract {
  const AnonymizeAdminUserUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<ErasureReport>> call(String userId) =>
      _repository.anonymizeUser(userId);
}
