import '../../models/admin/lockdown_status.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Estado del bloqueo global.
abstract interface class GetLockdownUseCaseContract {
  Future<AppResult<LockdownStatus>> call();
}

class GetLockdownUseCase implements GetLockdownUseCaseContract {
  const GetLockdownUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<LockdownStatus>> call() => _repository.getLockdown();
}
