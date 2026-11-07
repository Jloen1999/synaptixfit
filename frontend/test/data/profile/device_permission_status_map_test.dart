import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:synaptixfit/data/local_data_source/device_permissions_data_source.dart';
import 'package:synaptixfit/domain/enums/device_permission.dart';

/// Cada estado del sistema tiene su estado de la app: lo concedido a medias
/// cuenta como concedido y lo que no se puede volver a preguntar, como
/// denegado del todo (lleva a «Abrir ajustes»).
void main() {
  test('el mapa de estados cubre todos los de permission_handler', () {
    const expected = {
      PermissionStatus.granted: DevicePermissionStatus.granted,
      PermissionStatus.limited: DevicePermissionStatus.granted,
      PermissionStatus.provisional: DevicePermissionStatus.granted,
      PermissionStatus.denied: DevicePermissionStatus.denied,
      PermissionStatus.permanentlyDenied:
          DevicePermissionStatus.permanentlyDenied,
      PermissionStatus.restricted: DevicePermissionStatus.permanentlyDenied,
    };
    expect(expected.keys, containsAll(PermissionStatus.values));
    for (final entry in expected.entries) {
      expect(
        PluginDevicePermissionsDataSource.mapStatus(entry.key),
        entry.value,
        reason: '${entry.key}',
      );
    }
  });
}
