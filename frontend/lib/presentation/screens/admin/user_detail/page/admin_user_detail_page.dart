import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/user_role.dart';
import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/models/admin/admin_user.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../widgets/admin_dialogs.dart';
import '../../widgets/admin_labels.dart';
import '../../widgets/admin_status.dart';
import '../../widgets/admin_widgets.dart';
import '../bloc/admin_user_detail_bloc.dart';
import 'admin_user_dialogs.dart';
import 'admin_user_stats_tab.dart';
import 'admin_user_timeline_tab.dart';

/// Detalle de un usuario con sub-pestañas Perfil, Estadísticas y Timeline.
class AdminUserDetailPage extends StatelessWidget {
  const AdminUserDetailPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AdminUserDetailBloc>()
            ..add(AdminUserDetailEvent.started(userId)),
      child: _AdminUserDetailView(userId: userId),
    );
  }
}

class _AdminUserDetailView extends StatelessWidget with ErrorsMessageMixin {
  const _AdminUserDetailView({required this.userId});

  final String userId;

  Future<void> _onEffect(BuildContext context, AdminUserEffect effect) async {
    final l10n = context.localizations;
    switch (effect) {
      case AdminUserSavedEffect():
        context.showSnack(l10n.commonSaved);
      case AdminUserFailureEffect(:final error):
        context.showSnack(errorMessage(context, error));
      case AdminUserExportedEffect(:final json):
        final saved = await saveAdminJsonFile(
          fileName: 'synaptixfit_usuario_$userId.json',
          json: json,
        );
        if (context.mounted) {
          context.showSnack(
            saved ? l10n.adminUserExportSaved : l10n.adminUserExportCancelled,
          );
        }
      case AdminUserErasedEffect(:final action, :final report):
        await showAdminErasureReportDialog(context, report);
        if (action == AdminUserAction.delete && context.mounted) {
          context.pop(true);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<AdminUserDetailBloc, AdminUserDetailState>(
      listenWhen: (a, b) => a.effect != b.effect && b.effect != null,
      listener: (context, state) => _onEffect(context, state.effect!),
      builder: (context, state) {
        final detail = state.detail;
        final bloc = context.read<AdminUserDetailBloc>();
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppPageBar.wide(
              title: Text(detail?.account.fullName ?? l10n.adminUserTitle),
              actions: [
                IconButton(
                  tooltip: l10n.adminRefresh,
                  onPressed: state.status.isLoading
                      ? null
                      : () => bloc.add(const AdminUserDetailEvent.refreshed()),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
              bottom: detail == null
                  ? null
                  : TabBar(
                      tabs: [
                        Tab(text: l10n.adminUserTabProfile),
                        Tab(text: l10n.adminUserTabStats),
                        Tab(text: l10n.adminUserTabTimeline),
                      ],
                    ),
            ),
            body: switch (state.status) {
              AdminStatus.failure when detail == null => AppErrorView(
                error: state.error!,
                onRetry: () => bloc.add(const AdminUserDetailEvent.refreshed()),
              ),
              _ when detail == null => const AppSkeletonList(
                count: 6,
                height: 120,
              ),
              _ => Column(
                children: [
                  if (state.status.isLoading || state.busyAction != null)
                    const LinearProgressIndicator(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ProfileTab(state: state, detail: detail),
                        AdminUserStatsTab(state: state),
                        AdminUserTimelineTab(state: state),
                      ],
                    ),
                  ),
                ],
              ),
            },
          ),
        );
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.state, required this.detail});

  final AdminUserDetailState state;
  final AdminUserDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final account = detail.account;
    final wellbeing = detail.wellbeingProfile;
    final academic = detail.academicProfile;
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        AdminContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccountHeader(account: account),
              const SizedBox(height: TokensSpacing.m),
              _ActionsCard(state: state, account: account),
              const SizedBox(height: TokensSpacing.m),
              _InfoCard(
                title: l10n.adminUserAccountSection,
                rows: [
                  (l10n.adminFieldId, account.id),
                  (l10n.fieldEmail, account.email),
                  (l10n.adminFieldRole, account.role.adminLabel(l10n)),
                  (l10n.adminFieldPrivacy, _privacy(l10n, account)),
                  (l10n.adminFieldTotalXp, AdminFormat.number(account.totalXp)),
                  (
                    l10n.adminFieldStreak,
                    l10n.adminUsersStreak(account.streak),
                  ),
                  (l10n.adminFieldLogin, _login(l10n, account)),
                  (
                    l10n.adminFieldCreatedAt,
                    AdminFormat.dateTime(account.createdAt),
                  ),
                  if (account.deletedAt != null)
                    (
                      l10n.adminFieldDeletedAt,
                      AdminFormat.dateTime(account.deletedAt),
                    ),
                ],
              ),
              const SizedBox(height: TokensSpacing.m),
              _InfoCard(
                title: l10n.adminUserWellbeingSection,
                emptyText: wellbeing == null ? l10n.adminUserNoProfile : null,
                rows: wellbeing == null
                    ? const []
                    : [
                        (l10n.adminFieldAge, _text(wellbeing.age)),
                        (l10n.adminFieldSex, _text(wellbeing.sex)),
                        (
                          l10n.adminFieldWeight,
                          _unit(wellbeing.weightKg, 'kg'),
                        ),
                        (
                          l10n.adminFieldHeight,
                          _unit(wellbeing.heightCm, 'cm'),
                        ),
                        (
                          l10n.adminFieldBmi,
                          AdminFormat.decimal(wellbeing.bmi),
                        ),
                        (
                          l10n.adminFieldActivityLevel,
                          _text(wellbeing.activityLevel),
                        ),
                        (l10n.adminFieldMainGoal, _text(wellbeing.mainGoal)),
                        (
                          l10n.adminFieldDaysPerWeek,
                          _text(wellbeing.availableDaysPerWeek),
                        ),
                        (
                          l10n.adminFieldMinutesPerSession,
                          _text(wellbeing.minutesPerSession),
                        ),
                        (
                          l10n.adminFieldOnboarding,
                          wellbeing.onboardingCompleted
                              ? l10n.commonYes
                              : l10n.commonNo,
                        ),
                      ],
              ),
              const SizedBox(height: TokensSpacing.m),
              _InfoCard(
                title: l10n.adminUserAcademicSection,
                emptyText: academic == null ? l10n.adminUserNoProfile : null,
                rows: academic == null
                    ? const []
                    : [
                        (l10n.adminFieldUniversity, _text(academic.university)),
                        (l10n.adminFieldDegree, _text(academic.degree)),
                        (
                          l10n.adminFieldSemester,
                          _text(academic.currentSemester),
                        ),
                        (l10n.adminFieldModality, _text(academic.modality)),
                        (
                          l10n.adminFieldCredits,
                          _text(academic.semesterCredits),
                        ),
                        (
                          l10n.adminFieldStudyGoal,
                          _text(academic.weeklyStudyHoursGoal),
                        ),
                        (
                          l10n.adminFieldTargetGrade,
                          AdminFormat.decimal(academic.targetGrade),
                        ),
                        (
                          l10n.adminFieldClassesStart,
                          AdminFormat.date(academic.classesStart),
                        ),
                        (
                          l10n.adminFieldClassesEnd,
                          AdminFormat.date(academic.classesEnd),
                        ),
                      ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _text(Object? value) =>
      value == null || value.toString().isEmpty ? '—' : value.toString();

  static String _unit(double? value, String unit) =>
      value == null ? '—' : '${AdminFormat.decimal(value)} $unit';

  static String _privacy(AppLocalizations l10n, AdminUserAccount account) =>
      switch (account.privacy) {
        Visibility.private => l10n.adminPrivacyPrivate,
        Visibility.friends => l10n.adminPrivacyFriends,
        Visibility.public => l10n.adminPrivacyPublic,
      };

  static String _login(AppLocalizations l10n, AdminUserAccount account) {
    final methods = [
      if (account.hasPassword) l10n.adminLoginPassword,
      if (account.googleLinked) l10n.adminLoginGoogle,
    ];
    return methods.isEmpty ? '—' : methods.join(' · ');
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.account});

  final AdminUserAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                name: account.fullName,
                imageUrl: account.avatarUrl,
                radius: 28,
              ),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.fullName,
                      style: context.textStyles.titleLarge,
                    ),
                    SelectableText(
                      account.email,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    Wrap(
                      spacing: TokensSpacing.xs,
                      runSpacing: TokensSpacing.xs,
                      children: [
                        AppPill(
                          label: account.role.adminLabel(l10n),
                          color: account.role == UserRole.admin
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          icon: account.role == UserRole.admin
                              ? Icons.admin_panel_settings_outlined
                              : Icons.person_outline_rounded,
                        ),
                        if (account.shadowbanned)
                          AppPill(
                            label: l10n.adminTagShadowban,
                            color: context.palette.warning,
                            icon: Icons.visibility_off_outlined,
                          ),
                        if (account.deleted)
                          AppPill(
                            label: l10n.adminTagDeleted,
                            color: colors.error,
                            icon: Icons.block_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          XpProgressBar(
            level: account.level,
            levelXp: account.levelXp,
            levelThreshold: account.levelThreshold,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows, this.emptyText});

  final String title;
  final List<(String, String)> rows;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          if (emptyText != null)
            Text(
              emptyText!,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          for (final (label, value) in rows)
            AdminKeyValue(label: label, value: value),
        ],
      ),
    );
  }
}

/// Acciones administrativas sobre la cuenta, con confirmación.
class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.state, required this.account});

  final AdminUserDetailState state;
  final AdminUserAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    final bloc = context.read<AdminUserDetailBloc>();
    final isSelf = context.read<SessionBloc>().account?.id == account.id;
    final deleted = account.deleted;
    final busy = state.busyAction != null;

    // Sobre la propia cuenta el servidor rechaza rol, shadowban y borrados;
    // una cuenta eliminada solo admite exportar o eliminar.
    final canEdit = !busy && !deleted;
    final canTarget = canEdit && !isSelf;

    Future<void> confirmThen(
      String title,
      String message,
      String confirmLabel,
      AdminUserDetailEvent event, {
      bool destructive = false,
      bool typeEmail = false,
    }) async {
      final ok = await showAdminConfirmDialog(
        context,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        destructive: destructive,
        typeToConfirm: typeEmail ? account.email : null,
      );
      if (ok) bloc.add(event);
    }

    final actions = <_ActionSpec>[
      _ActionSpec(
        icon: Icons.edit_outlined,
        label: l10n.adminUserEditIdentity,
        busy: state.busyAction == AdminUserAction.identity,
        onPressed: !canEdit
            ? null
            : () async {
                final result = await showAdminIdentityDialog(context, account);
                if (result == null ||
                    (result.fullName == null && result.email == null)) {
                  return;
                }
                bloc.add(
                  AdminUserDetailEvent.identityUpdated(
                    fullName: result.fullName,
                    email: result.email,
                  ),
                );
              },
      ),
      _ActionSpec(
        icon: Icons.star_outline_rounded,
        label: l10n.adminUserSetProgress,
        busy: state.busyAction == AdminUserAction.progress,
        onPressed: !canEdit
            ? null
            : () async {
                final result = await showAdminProgressDialog(context, account);
                if (result == null) return;
                bloc.add(
                  AdminUserDetailEvent.progressSet(
                    level: result.level,
                    levelXp: result.levelXp,
                  ),
                );
              },
      ),
      _ActionSpec(
        icon: Icons.admin_panel_settings_outlined,
        label: l10n.adminUserChangeRole,
        busy: state.busyAction == AdminUserAction.role,
        onPressed: !canTarget
            ? null
            : () async {
                final role = await showAdminRoleDialog(context, account.role);
                if (role == null || !context.mounted) return;
                await confirmThen(
                  l10n.adminUserChangeRole,
                  l10n.adminUserChangeRoleConfirm(
                    account.fullName,
                    role.adminLabel(l10n),
                  ),
                  l10n.commonConfirm,
                  AdminUserDetailEvent.roleChanged(role),
                );
              },
      ),
      _ActionSpec(
        icon: account.shadowbanned
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        label: account.shadowbanned
            ? l10n.adminUserShadowbanRemove
            : l10n.adminUserShadowbanApply,
        busy: state.busyAction == AdminUserAction.shadowban,
        onPressed: !canTarget
            ? null
            : () => confirmThen(
                account.shadowbanned
                    ? l10n.adminUserShadowbanRemove
                    : l10n.adminUserShadowbanApply,
                account.shadowbanned
                    ? l10n.adminUserShadowbanRemoveConfirm
                    : l10n.adminUserShadowbanApplyConfirm,
                l10n.commonConfirm,
                AdminUserDetailEvent.shadowbanChanged(
                  shadowbanned: !account.shadowbanned,
                ),
                destructive: !account.shadowbanned,
              ),
      ),
      _ActionSpec(
        icon: Icons.download_rounded,
        label: l10n.adminUserExport,
        busy: state.busyAction == AdminUserAction.export,
        onPressed: busy
            ? null
            : () => bloc.add(const AdminUserDetailEvent.exportRequested()),
      ),
      _ActionSpec(
        icon: Icons.cleaning_services_outlined,
        label: l10n.adminUserWipe,
        destructive: true,
        busy: state.busyAction == AdminUserAction.wipe,
        onPressed: !canTarget
            ? null
            : () => confirmThen(
                l10n.adminUserWipe,
                l10n.adminUserWipeConfirm,
                l10n.adminUserWipe,
                const AdminUserDetailEvent.wipeRequested(),
                destructive: true,
                typeEmail: true,
              ),
      ),
      _ActionSpec(
        icon: Icons.person_off_outlined,
        label: l10n.adminUserAnonymize,
        destructive: true,
        busy: state.busyAction == AdminUserAction.anonymize,
        onPressed: !canTarget
            ? null
            : () => confirmThen(
                l10n.adminUserAnonymize,
                l10n.adminUserAnonymizeConfirm,
                l10n.adminUserAnonymize,
                const AdminUserDetailEvent.anonymizeRequested(),
                destructive: true,
                typeEmail: true,
              ),
      ),
      _ActionSpec(
        icon: Icons.delete_forever_outlined,
        label: l10n.adminUserDelete,
        destructive: true,
        busy: state.busyAction == AdminUserAction.delete,
        onPressed: busy || isSelf
            ? null
            : () => confirmThen(
                l10n.adminUserDelete,
                l10n.adminUserDeleteConfirm,
                l10n.adminUserDelete,
                const AdminUserDetailEvent.deleteRequested(),
                destructive: true,
                typeEmail: true,
              ),
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(title: l10n.adminUserActionsSection),
          if (isSelf || deleted)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.s),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: TokensSpacing.s),
                  Expanded(
                    child: Text(
                      isSelf
                          ? l10n.adminUserSelfNotice
                          : l10n.adminUserDeletedNotice,
                      style: context.textStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.s,
            children: [
              for (final action in actions) _ActionButton(spec: action),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionSpec {
  const _ActionSpec({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool busy;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.spec});

  final _ActionSpec spec;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = spec.destructive ? colors.error : null;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 44),
        side: spec.destructive && spec.onPressed != null
            ? BorderSide(color: colors.error.withValues(alpha: 0.6))
            : null,
      ),
      onPressed: spec.onPressed,
      icon: spec.busy
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(spec.icon, size: 18),
      label: Text(spec.label),
    );
  }
}
