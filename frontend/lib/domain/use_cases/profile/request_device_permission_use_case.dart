import '../../enums/device_permission.dart';
import '../../models/result/app_result.dart';
import '../../repositories/device_permissions_repository_contract.dart';

/// Pide al sistema un permiso del móvil (después de explicar para qué sirve)
/// y devuelve cómo queda.
abstract interface class RequestDevicePermissionUseCaseContract {
  Future<AppResult<DevicePermissionStatus>> call(DevicePermission permission);
}

class RequestDevicePermissionUseCase
    implements RequestDevicePermissionUseCaseContract {
  const RequestDevicePermissionUseCase(this._repository);

  final DevicePermissionsRepositoryContract _repository;

  @override
  Future<AppResult<DevicePermissionStatus>> call(DevicePermission permission) =>
      _repository.request(permission);
}
