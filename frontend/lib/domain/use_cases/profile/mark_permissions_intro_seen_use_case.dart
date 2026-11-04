import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/device_permissions_repository_contract.dart';

/// Recuerda en este dispositivo que ya se enseñó el paso «Permisos» (se
/// conteste o no): después se cambian desde Ajustes › Permisos.
abstract interface class MarkPermissionsIntroSeenUseCaseContract {
  Future<AppResult<Unit>> call();
}

class MarkPermissionsIntroSeenUseCase
    implements MarkPermissionsIntroSeenUseCaseContract {
  const MarkPermissionsIntroSeenUseCase(this._repository);

  final DevicePermissionsRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call() => _repository.markIntroSeen();
}
