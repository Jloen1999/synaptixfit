import '../../enums/device_permission.dart';
import '../../models/result/app_result.dart';
import '../../repositories/device_permissions_repository_contract.dart';

/// Cómo está un permiso del móvil (concedido, denegado, denegado del todo o
/// innecesario en esta plataforma).
abstract interface class GetDevicePermissionStatusUseCaseContract {
  Future<AppResult<DevicePermissionStatus>> call(DevicePermission permission);
}

class GetDevicePermissionStatusUseCase
    implements GetDevicePermissionStatusUseCaseContract {
  const GetDevicePermissionStatusUseCase(this._repository);

  final DevicePermissionsRepositoryContract _repository;

  @override
  Future<AppResult<DevicePermissionStatus>> call(DevicePermission permission) =>
      _repository.status(permission);
}
