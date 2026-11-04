part of 'permissions_bloc.dart';

@freezed
sealed class PermissionsEvent with _$PermissionsEvent {
  /// Lee cómo están [permissions] (los que enseña la pantalla).
  const factory PermissionsEvent.started({
    @Default(DevicePermission.values) List<DevicePermission> permissions,
  }) = PermissionsStarted;

  /// «Permitir»: pide el permiso al sistema.
  const factory PermissionsEvent.requested(DevicePermission permission) =
      PermissionsRequested;

  /// «Abrir ajustes» para un permiso que el sistema ya no vuelve a preguntar.
  const factory PermissionsEvent.settingsOpened(DevicePermission permission) =
      PermissionsSettingsOpened;

  /// La app vuelve a primer plano (p. ej. desde los ajustes del sistema).
  const factory PermissionsEvent.resumed() = PermissionsResumed;

  /// «Ahora no» en el paso «Permisos».
  const factory PermissionsEvent.skipped(DevicePermission permission) =
      PermissionsSkipped;

  /// «Continuar» en el paso «Permisos»: no se vuelve a enseñar.
  const factory PermissionsEvent.introFinished() = PermissionsIntroFinished;
}
