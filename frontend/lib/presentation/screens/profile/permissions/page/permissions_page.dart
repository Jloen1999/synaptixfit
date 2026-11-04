import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/permissions_bloc.dart';
import 'permission_tile.dart';

/// Ajustes › Permisos del móvil (`/profile/settings/permissions`): cómo está
/// cada permiso y qué hacer. Al volver de los ajustes del sistema se comprueba
/// otra vez.
class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<PermissionsBloc>()..add(const PermissionsEvent.started()),
      child: const PermissionsResumeListener(child: _PermissionsView()),
    );
  }
}

/// Vuelve a leer los permisos cuando la app vuelve a primer plano (p. ej.
/// desde los ajustes del sistema, donde se cambian los bloqueados).
class PermissionsResumeListener extends StatefulWidget {
  const PermissionsResumeListener({super.key, required this.child});

  final Widget child;

  @override
  State<PermissionsResumeListener> createState() =>
      _PermissionsResumeListenerState();
}

class _PermissionsResumeListenerState extends State<PermissionsResumeListener> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () {
        if (mounted) {
          context.read<PermissionsBloc>().add(const PermissionsEvent.resumed());
        }
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PermissionsView extends StatelessWidget with ErrorsMessageMixin {
  const _PermissionsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar.reading(title: Text(l10n.profilePermissionsTitle)),
      body: BlocConsumer<PermissionsBloc, PermissionsState>(
        listenWhen: (a, b) =>
            b.statuses.isNotEmpty && b.error != null && a.error != b.error,
        listener: (context, state) =>
            context.showSnack(errorMessage(context, state.error!)),
        builder: (context, state) {
          if (state.loading && state.statuses.isEmpty) {
            return const AppSkeletonList(height: TokensSize.permissionSkeleton);
          }
          // Sin poder leer el estado no se enseña «Sin permitir», que podría
          // ser falso: error con «Reintentar».
          final error = state.error;
          if (state.statuses.isEmpty && error != null) {
            return AppErrorView(
              error: error,
              onRetry: () => context.read<PermissionsBloc>().add(
                const PermissionsEvent.started(),
              ),
            );
          }
          final applicable = state.applicable;
          return ProfileScrollBody(
            children: [
              Text(
                l10n.profilePermissionsIntro,
                style: context.textStyles.bodyLarge,
              ),
              const SizedBox(height: TokensSpacing.m),
              if (applicable.isEmpty)
                AppInlineMessage(
                  message: l10n.profilePermissionsNoneNeeded,
                  tone: AppMessageTone.success,
                )
              else
                for (final permission in applicable) ...[
                  PermissionTile(
                    permission: permission,
                    status: state.statusOf(permission),
                    requested: state.requested.contains(permission),
                    busy: state.busy == permission,
                    onAllow: () => context.read<PermissionsBloc>().add(
                      PermissionsEvent.requested(permission),
                    ),
                    onOpenSettings: () => context.read<PermissionsBloc>().add(
                      PermissionsEvent.settingsOpened(permission),
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.m),
                ],
              Text(
                l10n.profilePermissionsDeviceNote,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.l),
            ],
          );
        },
      ),
    );
  }
}
