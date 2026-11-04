import '../../domain/enums/device_permission.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/device_permissions_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/device_permissions_data_source.dart';

/// Implementa [DevicePermissionsRepositoryContract] con
/// [DevicePermissionsDataSource].
class DevicePermissionsRepository
    implements DevicePermissionsRepositoryContract {
  const DevicePermissionsRepository(this._source);

  final DevicePermissionsDataSource _source;

  @override
  Future<AppResult<DevicePermissionStatus>> status(
    DevicePermission permission,
  ) => RepositoryErrorHandler.guard(() => _source.status(permission));

  @override
  Future<AppResult<DevicePermissionStatus>> request(
    DevicePermission permission,
  ) => RepositoryErrorHandler.guard(() => _source.request(permission));

  @override
  Future<AppResult<Unit>> openSettings(DevicePermission permission) =>
      RepositoryErrorHandler.guard(() async {
        await _source.openSettings(permission);
        return unit;
      });

  @override
  Future<AppResult<bool>> introSeen() =>
      RepositoryErrorHandler.guard(_source.introSeen);

  @override
  Future<AppResult<Unit>> markIntroSeen() =>
      RepositoryErrorHandler.guard(() async {
        await _source.markIntroSeen();
        return unit;
      });
}
