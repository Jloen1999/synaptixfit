import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/permissions_bloc.dart';
import 'permission_tile.dart';
import 'permissions_page.dart';

/// Paso «Permisos» (`/permissions-intro`): se enseña una vez por dispositivo,
/// al terminar el onboarding o, a quien ya lo hizo, desde Inicio. Cada permiso
/// explica para qué sirve con «Permitir» y «Ahora no»; «Continuar» sigue a
/// [nextPath] (o vuelve atrás si se abrió encima de otra pantalla).
class PermissionsIntroPage extends StatelessWidget {
  const PermissionsIntroPage({super.key, required this.nextPath});

  final String nextPath;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<PermissionsBloc>()..add(const PermissionsEvent.started()),
      child: PermissionsResumeListener(
        child: _PermissionsIntroView(nextPath: nextPath),
      ),
    );
  }
}

class _PermissionsIntroView extends StatelessWidget with ErrorsMessageMixin {
  const _PermissionsIntroView({required this.nextPath});

  final String nextPath;

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(nextPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<PermissionsBloc, PermissionsState>(
      listenWhen: (a, b) =>
          (b.introFinished && !a.introFinished) ||
          (b.error != null && a.error != b.error) ||
          // Sin permisos que pedir en este dispositivo (web, escritorio): no
          // hay nada que enseñar.
          (a.loading && !b.loading && b.applicable.isEmpty),
      listener: (context, state) {
        if (state.introFinished) {
          _leave(context);
        } else if (state.error case final error?) {
          context.showSnack(errorMessage(context, error));
        } else {
          context.read<PermissionsBloc>().add(
            const PermissionsEvent.introFinished(),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<PermissionsBloc>();
        return PopScope(
          // Volver atrás cuenta como «Continuar»: no se vuelve a enseñar.
          canPop: state.introFinished,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) bloc.add(const PermissionsEvent.introFinished());
          },
          child: Scaffold(
            appBar: AppPageBar.reading(
              automaticallyImplyLeading: false,
              title: Text(l10n.profilePermissionsIntroTitle),
            ),
            body: state.loading && state.statuses.isEmpty
                ? const AppSkeletonList(height: TokensSize.permissionSkeleton)
                : state.statuses.isEmpty && state.error != null
                ? AppErrorView(
                    error: state.error!,
                    onRetry: () => bloc.add(
                      const PermissionsEvent.started(),
                    ),
                  )
                : ProfileScrollBody(
                    children: [
                      Text(
                        l10n.profilePermissionsIntro,
                        style: context.textStyles.bodyLarge,
                      ),
                      const SizedBox(height: TokensSpacing.m),
                      for (final permission in state.applicable) ...[
                        PermissionTile(
                          permission: permission,
                          status: state.statusOf(permission),
                          requested: state.requested.contains(permission),
                          busy: state.busy == permission,
                          skipped: state.skipped.contains(permission),
                          onSkip: () =>
                              bloc.add(PermissionsEvent.skipped(permission)),
                          onAllow: () =>
                              bloc.add(PermissionsEvent.requested(permission)),
                          onOpenSettings: () => bloc.add(
                            PermissionsEvent.settingsOpened(permission),
                          ),
                        ),
                        const SizedBox(height: TokensSpacing.m),
                      ],
                      Text(
                        l10n.profilePermissionsIntroLater,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: TokensSpacing.l),
                    ],
                  ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.all(TokensSpacing.m),
              child: AppContentWidth.reading(
                child: AppPrimaryButton(
                  label: l10n.profilePermissionsIntroContinue,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () =>
                      bloc.add(const PermissionsEvent.introFinished()),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
