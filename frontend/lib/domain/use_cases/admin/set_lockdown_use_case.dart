import '../../models/admin/lockdown_status.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Activa o desactiva el bloqueo global.
abstract interface class SetLockdownUseCaseContract {
  Future<AppResult<LockdownStatus>> call({required bool active});
}

class SetLockdownUseCase implements SetLockdownUseCaseContract {
  const SetLockdownUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<LockdownStatus>> call({required bool active}) =>
      _repository.setLockdown(active: active);
}
