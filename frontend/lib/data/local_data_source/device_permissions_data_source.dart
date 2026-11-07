import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums/device_permission.dart';

/// Permisos del sistema con `permission_handler` y la marca «paso Permisos ya
/// enseñado» en el teléfono.
abstract interface class DevicePermissionsDataSource {
  Future<DevicePermissionStatus> status(DevicePermission permission);

  Future<DevicePermissionStatus> request(DevicePermission permission);

  Future<void> openSettings(DevicePermission permission);

  Future<bool> introSeen();

  Future<void> markIntroSeen();
}

/// [DevicePermissionsDataSource] real. En web y escritorio no hay permisos que
/// pedir: todo es [DevicePermissionStatus.notApplicable].
class PluginDevicePermissionsDataSource implements DevicePermissionsDataSource {
  PluginDevicePermissionsDataSource([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _introKey = 'sfx_permissions_intro_seen';

  final SharedPreferencesAsync _preferences;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// El permiso del sistema que corresponde; `null` si no existe aquí. Las
  /// alarmas exactas solo existen en Android.
  Permission? _systemPermission(DevicePermission permission) {
    if (!_android && !_ios) return null;
    return switch (permission) {
      DevicePermission.notifications => Permission.notification,
      DevicePermission.camera => Permission.camera,
      // Nunca «siempre» (ACCESS_BACKGROUND_LOCATION): la grabación sigue con
      // la pantalla apagada gracias al servicio en primer plano.
      DevicePermission.location => Permission.locationWhenInUse,
      DevicePermission.exactAlarms =>
        _android ? Permission.scheduleExactAlarm : null,
    };
  }

  @override
  Future<DevicePermissionStatus> status(DevicePermission permission) async {
    final system = _systemPermission(permission);
    if (system == null) return DevicePermissionStatus.notApplicable;
    return mapStatus(await system.status);
  }

  @override
  Future<DevicePermissionStatus> request(DevicePermission permission) async {
    final system = _systemPermission(permission);
    if (system == null) return DevicePermissionStatus.notApplicable;
    return mapStatus(await system.request());
  }

  @override
  Future<void> openSettings(DevicePermission permission) async {
    final system = _systemPermission(permission);
    if (system == null) return;
    // Las alarmas exactas tienen su propia pantalla del sistema, que es lo
    // que abre pedirlas; el resto se cambia en los ajustes de la app.
    if (permission == DevicePermission.exactAlarms) {
      await system.request();
      return;
    }
    await openAppSettings();
  }

  @override
  Future<bool> introSeen() async =>
      await _preferences.getBool(_introKey) ?? false;

  @override
  Future<void> markIntroSeen() => _preferences.setBool(_introKey, true);

  /// Traduce el estado de `permission_handler` al del dominio.
  @visibleForTesting
  static DevicePermissionStatus mapStatus(PermissionStatus status) =>
      switch (status) {
        PermissionStatus.granted ||
        PermissionStatus.limited ||
        PermissionStatus.provisional => DevicePermissionStatus.granted,
        // «Restringido» (control parental, empresa) tampoco se puede volver
        // a preguntar: como denegado del todo.
        PermissionStatus.permanentlyDenied ||
        PermissionStatus.restricted => DevicePermissionStatus.permanentlyDenied,
        PermissionStatus.denied => DevicePermissionStatus.denied,
      };
}
