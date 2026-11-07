import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../audit/page/admin_audit_page.dart';
import '../../exercises/page/admin_exercises_page.dart';
import '../../metrics/page/admin_metrics_page.dart';
import '../../reports/page/admin_reports_page.dart';
import '../../users/page/admin_users_page.dart';
import '../../widgets/admin_dialogs.dart';
import '../../widgets/admin_widgets.dart';
import '../bloc/admin_hub_bloc.dart';
import '../../../../widgets/widgets.dart';

/// Panel de administración: pestañas KPIs, Usuarios, Contenido, Ejercicios y
/// Auditoría, con el interruptor del bloqueo global en la cabecera.
class AdminHubPage extends StatelessWidget {
  const AdminHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminHubBloc>()..add(const AdminHubEvent.started()),
      child: const _AdminHubView(),
    );
  }
}

class _AdminHubView extends StatelessWidget with ErrorsMessageMixin {
  const _AdminHubView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final tabs = [
      (Icons.insights_outlined, l10n.adminTabMetrics),
      (AppIcons.friends, l10n.adminTabUsers),
      (Icons.flag_outlined, l10n.adminTabContent),
      (Icons.fitness_center_outlined, l10n.adminTabExercises),
      (AppIcons.history, l10n.adminTabAudit),
    ];
    return BlocListener<AdminHubBloc, AdminHubState>(
      // Solo al terminar un cambio de bloqueo (no en la carga inicial).
      listenWhen: (a, b) => a.updating && !b.updating,
      listener: (context, state) {
        final error = state.actionError;
        if (error != null) {
          context.showSnack(errorMessage(context, error));
        } else if (state.lockdown != null) {
          context.showSnack(
            state.lockdown!.active
                ? l10n.adminLockdownActivated
                : l10n.adminLockdownDeactivated,
          );
        }
      },
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: AppPageBar.wide(
            title: Text(l10n.adminTitle),
            actions: const [_LockdownControl()],
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final (icon, label) in tabs)
                  Tab(icon: Icon(icon, size: 20), text: label),
              ],
            ),
          ),
          body: const Column(
            children: [
              _LockdownBanner(),
              Expanded(
                child: TabBarView(
                  children: [
                    AdminKeepAlive(child: AdminMetricsTab()),
                    AdminKeepAlive(child: AdminUsersTab()),
                    AdminKeepAlive(child: AdminReportsTab()),
                    AdminKeepAlive(child: AdminExercisesTab()),
                    AdminKeepAlive(child: AdminAuditTab()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interruptor del bloqueo global con confirmación.
class _LockdownControl extends StatelessWidget {
  const _LockdownControl();

  Future<void> _toggle(BuildContext context, bool active) async {
    final l10n = context.localizations;
    final bloc = context.read<AdminHubBloc>();
    final confirmed = await showAdminConfirmDialog(
      context,
      title: active
          ? l10n.adminLockdownEnableTitle
          : l10n.adminLockdownDisableTitle,
      message: active
          ? l10n.adminLockdownEnableMessage
          : l10n.adminLockdownDisableMessage,
      confirmLabel: active
          ? l10n.adminLockdownEnableAction
          : l10n.adminLockdownDisableAction,
      destructive: active,
    );
    if (confirmed) bloc.add(AdminHubEvent.lockdownChanged(active: active));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<AdminHubBloc, AdminHubState>(
      builder: (context, state) {
        if (state.loadError != null) {
          return IconButton(
            tooltip: l10n.adminLockdownLoadError,
            icon: Icon(Icons.sync_problem_rounded, color: context.colors.error),
            onPressed: () =>
                context.read<AdminHubBloc>().add(const AdminHubEvent.started()),
          );
        }
        final lockdown = state.lockdown;
        final busy = state.loading || state.updating || lockdown == null;
        final active = lockdown?.active ?? false;
        return Padding(
          padding: const EdgeInsets.only(right: TokensSpacing.s),
          child: Tooltip(
            message: l10n.adminLockdownTooltip,
            // Un solo nodo: la etiqueta visible da nombre al interruptor y no
            // se lee dos veces.
            child: MergeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: TokensSize.iconS,
                    color: active ? context.colors.error : null,
                  ),
                  const SizedBox(width: TokensSpacing.xs),
                  Text(
                    l10n.adminLockdownLabel,
                    style: context.textStyles.labelLarge,
                  ),
                  Switch(
                    value: active,
                    onChanged: busy ? null : (value) => _toggle(context, value),
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

/// Aviso visible mientras el bloqueo global está activo.
class _LockdownBanner extends StatelessWidget {
  const _LockdownBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminHubBloc, AdminHubState>(
      buildWhen: (a, b) => a.lockdown != b.lockdown,
      builder: (context, state) {
        final lockdown = state.lockdown;
        if (lockdown == null || !lockdown.active) {
          return const SizedBox.shrink();
        }
        final colors = context.colors;
        return Material(
          color: colors.errorContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensSpacing.m,
              vertical: TokensSpacing.s,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_rounded,
                  color: colors.onErrorContainer,
                  size: TokensSize.iconS,
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Text(
                    lockdown.startedAt == null
                        ? context.localizations.adminLockdownBanner
                        : context.localizations.adminLockdownBannerSince(
                            AdminFormat.dateTime(lockdown.startedAt),
                          ),
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: colors.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
