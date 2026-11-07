import 'package:flutter/material.dart';

import '../../../../../domain/enums/device_permission.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';

/// Icono de cada permiso.
IconData permissionIcon(DevicePermission permission) => switch (permission) {
  DevicePermission.notifications => Icons.notifications_active_outlined,
  DevicePermission.exactAlarms => Icons.alarm_rounded,
  DevicePermission.camera => Icons.photo_camera_outlined,
  DevicePermission.location => Icons.location_on_outlined,
};

/// Nombre corto del permiso.
String permissionTitle(BuildContext context, DevicePermission permission) {
  final l10n = context.localizations;
  return switch (permission) {
    DevicePermission.notifications => l10n.profilePermissionNotificationsTitle,
    DevicePermission.exactAlarms => l10n.profilePermissionExactAlarmsTitle,
    DevicePermission.camera => l10n.profilePermissionCameraTitle,
    DevicePermission.location => l10n.profilePermissionLocationTitle,
  };
}

/// Para qué sirve, en una frase, y qué pasa si no se da.
String permissionWhy(BuildContext context, DevicePermission permission) {
  final l10n = context.localizations;
  return switch (permission) {
    DevicePermission.notifications => l10n.profilePermissionNotificationsWhy,
    DevicePermission.exactAlarms => l10n.profilePermissionExactAlarmsWhy,
    DevicePermission.camera => l10n.profilePermissionCameraWhy,
    DevicePermission.location => l10n.profilePermissionLocationWhy,
  };
}

/// Pregunta de la hoja que se abre justo antes de usarlo.
String permissionAsk(BuildContext context, DevicePermission permission) {
  final l10n = context.localizations;
  return switch (permission) {
    DevicePermission.notifications => l10n.profilePermissionNotificationsAsk,
    DevicePermission.exactAlarms => l10n.profilePermissionExactAlarmsAsk,
    DevicePermission.camera => l10n.profilePermissionCameraAsk,
    DevicePermission.location => l10n.profilePermissionLocationAsk,
  };
}

/// Una fila de permiso: qué es, para qué sirve, cómo está y qué se puede
/// hacer («Permitir», «Abrir ajustes» o nada si ya está permitido). En el
/// paso «Permisos» se añade «Ahora no» ([onSkip]).
class PermissionTile extends StatelessWidget {
  const PermissionTile({
    super.key,
    required this.permission,
    required this.status,
    required this.busy,
    required this.onAllow,
    required this.onOpenSettings,
    this.onSkip,
    this.skipped = false,
    this.requested = false,
  });

  final DevicePermission permission;
  final DevicePermissionStatus? status;
  final bool busy;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;
  final VoidCallback? onSkip;
  final bool skipped;

  /// Ya se pidió en esta pantalla: si sigue sin permitir, se explica.
  final bool requested;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final granted = status == DevicePermissionStatus.granted;
    final blocked = status == DevicePermissionStatus.permanentlyDenied;
    final (statusLabel, statusColor, statusIcon) = granted
        ? (
            l10n.profilePermissionStatusGranted,
            context.palette.success,
            Icons.check_circle_rounded,
          )
        : blocked
        ? (
            l10n.profilePermissionStatusBlocked,
            context.palette.warning,
            Icons.block_rounded,
          )
        : skipped
        ? (
            l10n.profilePermissionStatusLater,
            context.colors.onSurfaceVariant,
            Icons.schedule_rounded,
          )
        : (
            l10n.profilePermissionStatusDenied,
            context.colors.onSurfaceVariant,
            Icons.radio_button_unchecked_rounded,
          );
    final title = permissionTitle(context, permission);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    permissionIcon(permission),
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: TokensSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.textStyles.titleMedium),
                      const SizedBox(height: TokensSpacing.xs),
                      Text(
                        permissionWhy(context, permission),
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: TokensSpacing.s),
                      AppPill(
                        label: statusLabel,
                        color: statusColor,
                        icon: statusIcon,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (blocked) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(
              l10n.profilePermissionBlockedHint,
              style: context.textStyles.bodySmall,
            ),
          ] else if (requested && !granted) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(
              l10n.profilePermissionDeniedHint,
              style: context.textStyles.bodySmall,
            ),
          ],
          // «Permitir» en esta opción abre una pantalla del sistema, no una
          // pregunta: se avisa antes para que no sorprenda.
          if (!granted && !blocked && permission == DevicePermission.exactAlarms)
            Padding(
              padding: const EdgeInsets.only(top: TokensSpacing.s),
              child: Text(
                l10n.profilePermissionExactAlarmsOpensSettings,
                style: context.textStyles.bodySmall,
              ),
            ),
          // Ya permitido: se puede quitar desde los ajustes del móvil.
          if (granted) ...[
            const SizedBox(height: TokensSpacing.s),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: busy ? null : onOpenSettings,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(l10n.profilePermissionOpenSettings),
              ),
            ),
          ],
          if (!granted) ...[
            const SizedBox(height: TokensSpacing.m),
            Wrap(
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.s,
              alignment: WrapAlignment.end,
              children: [
                if (onSkip != null && !skipped && !blocked)
                  TextButton(
                    onPressed: busy ? null : onSkip,
                    child: Text(l10n.profilePermissionNotNow),
                  ),
                if (blocked)
                  AppSecondaryButton(
                    label: l10n.profilePermissionOpenSettings,
                    icon: const Icon(Icons.open_in_new_rounded),
                    onPressed: busy ? null : onOpenSettings,
                  )
                else
                  AppPrimaryButton(
                    label: l10n.profilePermissionAllow,
                    loading: busy,
                    onPressed: onAllow,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
