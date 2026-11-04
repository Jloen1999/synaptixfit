part of 'permissions_bloc.dart';

@freezed
abstract class PermissionsState with _$PermissionsState {
  const factory PermissionsState({
    @Default(true) bool loading,

    /// Permisos que enseña la pantalla, en su orden.
    @Default(<DevicePermission>[]) List<DevicePermission> shown,
    @Default(<DevicePermission, DevicePermissionStatus>{})
    Map<DevicePermission, DevicePermissionStatus> statuses,

    /// Permiso que se está pidiendo ahora.
    DevicePermission? busy,

    /// Ya se pidieron en esta pantalla (para no volver a ofrecer «Permitir»
    /// como si nada tras una negativa).
    @Default(<DevicePermission>{}) Set<DevicePermission> requested,

    /// «Ahora no» en el paso «Permisos».
    @Default(<DevicePermission>{}) Set<DevicePermission> skipped,
    @Default(false) bool introFinished,
    AppError? error,
  }) = _PermissionsState;

  const PermissionsState._();

  DevicePermissionStatus? statusOf(DevicePermission permission) =>
      statuses[permission];

  /// Los que existen en este dispositivo (en web o escritorio, ninguno).
  List<DevicePermission> get applicable => [
    for (final p in shown)
      if (statuses[p] != DevicePermissionStatus.notApplicable) p,
  ];
}
