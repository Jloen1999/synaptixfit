import '../enums/device_permission.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Permisos del sistema en este dispositivo y si ya se enseñó el paso
/// «Permisos» del primer inicio.
abstract interface class DevicePermissionsRepositoryContract {
  Future<AppResult<DevicePermissionStatus>> status(DevicePermission permission);

  /// Pide el permiso al sistema y devuelve cómo queda.
  Future<AppResult<DevicePermissionStatus>> request(
    DevicePermission permission,
  );

  /// Abre los ajustes de la app en el sistema (para un permiso denegado del
  /// todo). Para las alarmas exactas, su pantalla propia.
  Future<AppResult<Unit>> openSettings(DevicePermission permission);

  /// El paso «Permisos» ya se enseñó en este dispositivo.
  Future<AppResult<bool>> introSeen();

  Future<AppResult<Unit>> markIntroSeen();
}
