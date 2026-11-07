import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/device_permission.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../bloc/permissions_bloc.dart';
import 'permission_tile.dart';
import 'permissions_page.dart';

/// Qué eligió la persona en la hoja de permiso.
enum PermissionRequestResult {
  /// Permitido (o no hacía falta en este dispositivo): se puede seguir.
  granted,

  /// «Ahora no»: no se hace nada.
  notNow,

  /// Eligió la alternativa (p. ej. «Elegir de la galería» en vez de la cámara).
  alternative,
}

/// Se llama justo antes de usar algo que necesita [permission]. Si ya está
/// permitido (o no existe en esta plataforma) devuelve
/// [PermissionRequestResult.granted] sin enseñar nada. Si no, abre una hoja
/// corta que explica para qué sirve y ofrece «Permitir» o, si el sistema ya no
/// lo vuelve a preguntar, «Abrir ajustes»; al volver de los ajustes se
/// comprueba solo. [alternativeLabel] añade un camino sin el permiso.
Future<PermissionRequestResult> ensureDevicePermission(
  BuildContext context,
  DevicePermission permission, {
  String? alternativeLabel,
}) async {
  final bloc = getIt<PermissionsBloc>()
    ..add(PermissionsEvent.started(permissions: [permission]));
  try {
    final ready = await bloc.stream.firstWhere(
      (s) => !s.loading || s.error != null,
    );
    if (ready.statusOf(permission)?.usable ?? false) {
      return PermissionRequestResult.granted;
    }
    if (!context.mounted) return PermissionRequestResult.notNow;
    final result = await showModalBottomSheet<PermissionRequestResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: PermissionsResumeListener(
          child: _PermissionRequestSheet(
            permission: permission,
            alternativeLabel: alternativeLabel,
          ),
        ),
      ),
    );
    return result ?? PermissionRequestResult.notNow;
  } finally {
    unawaited(bloc.close());
  }
}

class _PermissionRequestSheet extends StatefulWidget {
  const _PermissionRequestSheet({
    required this.permission,
    required this.alternativeLabel,
  });

  final DevicePermission permission;
  final String? alternativeLabel;

  @override
  State<_PermissionRequestSheet> createState() =>
      _PermissionRequestSheetState();
}

class _PermissionRequestSheetState extends State<_PermissionRequestSheet> {
  // El foco empieza en la acción principal: con teclado o lector de pantalla
  // se decide sin recorrer toda la explicación.
  final _primaryFocus = FocusNode();

  DevicePermission get permission => widget.permission;
  String? get alternativeLabel => widget.alternativeLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _primaryFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _primaryFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<PermissionsBloc, PermissionsState>(
      listenWhen: (a, b) =>
          !(a.statusOf(permission)?.usable ?? false) &&
          (b.statusOf(permission)?.usable ?? false),
      // Concedido (al pulsar «Permitir» o al volver de los ajustes): se sigue.
      listener: (context, _) =>
          Navigator.pop(context, PermissionRequestResult.granted),
      builder: (context, state) {
        final status = state.statusOf(permission);
        final blocked = status == DevicePermissionStatus.permanentlyDenied;
        final deniedNow =
            state.requested.contains(permission) &&
            status == DevicePermissionStatus.denied;
        final bloc = context.read<PermissionsBloc>();
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.l,
              0,
              TokensSpacing.l,
              TokensSpacing.l,
            ),
            child: AppContentWidth.reading(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      permissionIcon(permission),
                      size: TokensSize.iconXl,
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  Semantics(
                    header: true,
                    child: Text(
                      permissionAsk(context, permission),
                      textAlign: TextAlign.center,
                      style: context.textStyles.titleLarge,
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.s),
                  Text(
                    permissionWhy(context, permission),
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodyLarge,
                  ),
                  if (blocked || deniedNow) ...[
                    const SizedBox(height: TokensSpacing.m),
                    AppInlineMessage(
                      message: blocked
                          ? l10n.profilePermissionBlockedHint
                          : l10n.profilePermissionDeniedHint,
                      tone: AppMessageTone.warning,
                    ),
                  ],
                  const SizedBox(height: TokensSpacing.l),
                  if (blocked)
                    AppPrimaryButton(
                      label: l10n.profilePermissionOpenSettings,
                      icon: AppIcons.openExternal,
                      focusNode: _primaryFocus,
                      onPressed: () =>
                          bloc.add(PermissionsEvent.settingsOpened(permission)),
                    )
                  else
                    AppPrimaryButton(
                      label: l10n.profilePermissionAllow,
                      focusNode: _primaryFocus,
                      loading: state.busy == permission,
                      onPressed: () =>
                          bloc.add(PermissionsEvent.requested(permission)),
                    ),
                  if (alternativeLabel case final label?) ...[
                    const SizedBox(height: TokensSpacing.s),
                    AppSecondaryButton(
                      label: label,
                      onPressed: () => Navigator.pop(
                        context,
                        PermissionRequestResult.alternative,
                      ),
                    ),
                  ],
                  const SizedBox(height: TokensSpacing.s),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, PermissionRequestResult.notNow),
                    child: Text(l10n.profilePermissionNotNow),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
