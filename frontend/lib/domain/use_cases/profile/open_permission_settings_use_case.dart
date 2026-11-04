import '../../enums/device_permission.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/device_permissions_repository_contract.dart';

/// Abre los ajustes del sistema para cambiar un permiso que ya no se puede
/// volver a preguntar.
abstract interface class OpenPermissionSettingsUseCaseContract {
  Future<AppResult<Unit>> call(DevicePermission permission);
}

class OpenPermissionSettingsUseCase
    implements OpenPermissionSettingsUseCaseContract {
  const OpenPermissionSettingsUseCase(this._repository);

  final DevicePermissionsRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(DevicePermission permission) =>
      _repository.openSettings(permission);
}
