import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/profile/academic_profile.dart';
import '../../../../../domain/models/profile/catalog.dart';
import '../../../../../domain/models/profile/profile_summary.dart';
import '../../../../../domain/models/profile/wellness_profile.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../profile_routes.dart';
import '../../widgets/profile_labels.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/profile_bloc.dart';

/// Perfil del usuario (`/profile`): cuenta, lo social, el perfil físico y el
/// académico. Ajustes se abre con el engranaje de la barra (un solo camino).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(const ProfileEvent.started()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget with ErrorsMessageMixin {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar.reading(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            tooltip: l10n.profileSettingsTitle,
            icon: const Icon(AppIcons.settings),
            onPressed: () => _open(context, ProfilePaths.settings),
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (a, b) => a.account != b.account || a.error != b.error,
        listener: (context, state) {
          final session = context.read<SessionBloc>();
          if (state.account case final account?
              when account != session.account) {
            session.add(SessionEvent.accountUpdated(account));
          }
          if (state.status == ProfileStatus.ready && state.error != null) {
            context.showSnack(errorMessage(context, state.error!));
          }
        },
        builder: (context, state) {
          final bloc = context.read<ProfileBloc>();
          return switch (state.status) {
            ProfileStatus.loading => const _ProfileSkeleton(),
            ProfileStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => bloc.add(const ProfileEvent.started()),
            ),
            ProfileStatus.ready => RefreshIndicator(
              onRefresh: () async {
                bloc.add(const ProfileEvent.refreshed());
                await bloc.stream.firstWhere((s) => !s.refreshing);
              },
              child: _ProfileContent(
                account: state.account!,
                summary: state.summary!,
                pendingRequests: state.pendingRequests,
              ),
            ),
          };
        },
      ),
    );
  }
}

/// Abre una pantalla del módulo y refresca el perfil al volver.
Future<void> _open(BuildContext context, String path) async {
  await context.push<Object?>(path);
  if (context.mounted) {
    context.read<ProfileBloc>().add(const ProfileEvent.refreshed());
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonGroup(
      child: ProfileScrollBody(
        physics: NeverScrollableScrollPhysics(),
        children: [
          AppSkeleton(height: 168),
          SizedBox(height: TokensSpacing.m),
          AppSkeleton(height: 180),
          SizedBox(height: TokensSpacing.m),
          AppSkeleton(height: 150),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.account,
    required this.summary,
    required this.pendingRequests,
  });

  final Account account;
  final ProfileSummary summary;
  final int pendingRequests;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return ProfileScrollBody(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _AccountHeader(account: account),
        if (!summary.onboarding.completed) ...[
          const SizedBox(height: TokensSpacing.m),
          AppCard(
            color: context.colors.primaryContainer,
            onTap: () => _open(context, ProfilePaths.onboarding),
            child: Row(
              children: [
                Icon(
                  Icons.flag_circle_rounded,
                  color: context.colors.onPrimaryContainer,
                ),
                const SizedBox(width: TokensSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileOnboardingBannerTitle,
                        style: context.textStyles.titleSmall?.copyWith(
                          color: context.colors.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        l10n.profileOnboardingBannerMessage,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.next, color: context.colors.onPrimaryContainer),
              ],
            ),
          ),
        ],
        // Fecha de nacimiento (ADR 0036): se sugiere sin bloquear; quien ya
        // dio su edad sigue igual hasta que la ponga.
        if (account.birthDate == null && summary.onboarding.completed) ...[
          const SizedBox(height: TokensSpacing.m),
          _MissingCard(
            icon: Icons.cake_outlined,
            color: context.palette.accent,
            message: l10n.profileBirthDateSuggestion,
            actionLabel: l10n.profileBirthDateAdd,
            onAction: () => _open(context, ProfilePaths.editAccount),
          ),
        ],
        const SizedBox(height: TokensSpacing.l),
        _SocialCard(account: account, pendingRequests: pendingRequests),
        // Solo los perfiles del ámbito que la persona usa.
        if (account.usageFocus.includesFitness) ...[
          const SizedBox(height: TokensSpacing.l),
          _WellnessSummary(profile: summary.wellness),
        ],
        if (account.usageFocus.includesAcademic) ...[
          const SizedBox(height: TokensSpacing.l),
          _AcademicSummary(profile: summary.academic, degrees: summary.degrees),
        ],
        if (account.isAdmin) ...[
          const SizedBox(height: TokensSpacing.l),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppFocusOutline(
              child: ListTile(
                leading: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: context.colors.primary,
                ),
                title: Text(l10n.profileAdminPanel),
                trailing: const Icon(AppIcons.next),
                onTap: () => context.push(ProfilePaths.adminPanel),
              ),
            ),
          ),
        ],
        const SizedBox(height: TokensSpacing.l),
      ],
    );
  }
}

/// Acceso a lo social desde el perfil: amigos (con las solicitudes que esperan
/// respuesta) y cómo ven los demás mi perfil.
class _SocialCard extends StatelessWidget {
  const _SocialCard({required this.account, required this.pendingRequests});

  final Account account;
  final int pendingRequests;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.profileSocialSection),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              AppFocusOutline(
                child: ListTile(
                  leading: const Icon(AppIcons.friends),
                  title: Text(l10n.profileFriends),
                  subtitle: pendingRequests > 0
                      ? Text(l10n.profileFriendsPending(pendingRequests))
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // El número ya lo dice el subtítulo: el globo es solo visual.
                      if (pendingRequests > 0)
                        ExcludeSemantics(
                          child: Badge(
                            label: Text(
                              pendingRequests > 99 ? '99+' : '$pendingRequests',
                            ),
                          ),
                        ),
                      const Icon(AppIcons.next),
                    ],
                  ),
                  onTap: () => _open(context, ProfilePaths.friends),
                ),
              ),
              const Divider(height: 1),
              AppFocusOutline(
                child: ListTile(
                  leading: const Icon(AppIcons.community),
                  title: Text(l10n.profileCommunity),
                  trailing: const Icon(AppIcons.next),
                  onTap: () => _open(context, ProfilePaths.community),
                ),
              ),
              const Divider(height: 1),
              AppFocusOutline(
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(l10n.profilePublicProfile),
                  // Con el perfil privado nadie más lo ve: decirlo tal cual.
                  subtitle: account.privacy == Visibility.private
                      ? Text(l10n.profilePublicProfilePrivateHint)
                      : null,
                  trailing: const Icon(AppIcons.next),
                  onTap: () =>
                      _open(context, ProfilePaths.publicProfile(account.id)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppAvatar(
                name: account.fullName,
                imageUrl: account.avatarUrl,
                radius: TokensSize.heroRing / 2,
              ),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.fullName,
                      style: context.textStyles.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      account.email,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          account.privacy.icon,
                          size: TokensSize.iconXs,
                          color: context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: TokensSpacing.xs),
                        Text(
                          account.privacy.label(l10n),
                          style: context.textStyles.labelMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.profileEditAccountTitle,
                icon: const Icon(AppIcons.edit),
                onPressed: () => _open(context, ProfilePaths.editAccount),
              ),
            ],
          ),
          // Nivel y XP se ven en Progreso (ADR 0038); aquí, solo la racha.
          const SizedBox(height: TokensSpacing.m),
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: TokensSize.iconS,
                color: context.palette.streak,
              ),
              const SizedBox(width: TokensSpacing.xs),
              Text(
                l10n.profileStreakDays(account.streak),
                style: context.textStyles.labelLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WellnessSummary extends StatelessWidget {
  const _WellnessSummary({required this.profile});

  final WellnessProfile? profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final p = profile;
    final number = NumberFormat('0.#');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.profileWellnessSection,
          actionLabel: p == null ? null : l10n.commonEdit,
          onAction: () => _open(context, ProfilePaths.editWellness),
        ),
        if (p == null)
          _MissingCard(
            icon: Icons.fitness_center_rounded,
            color: context.colors.secondary,
            message: l10n.profileWellnessMissing,
            actionLabel: l10n.profileCompleteAction,
            onAction: () => _open(context, ProfilePaths.editWellness),
          )
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        icon: Icons.speed_rounded,
                        color: context.palette.sessions,
                        value: p.bmi == null ? '—' : number.format(p.bmi),
                        label: l10n.profileBmiLabel,
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        icon: Icons.monitor_weight_outlined,
                        color: context.colors.secondary,
                        value: p.weightKg == null
                            ? '—'
                            : l10n.profileKgValue(number.format(p.weightKg)),
                        label: l10n.profileFieldWeightShort,
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        icon: Icons.height_rounded,
                        color: context.palette.calories,
                        value: p.heightCm == null
                            ? '—'
                            : l10n.profileCmValue(number.format(p.heightCm)),
                        label: l10n.profileFieldHeightShort,
                      ),
                    ),
                  ],
                ),
                const Divider(height: TokensSpacing.l),
                ProfileInfoRow(
                  icon: p.primaryGoal?.icon ?? Icons.flag_outlined,
                  label: l10n.profileFieldGoal,
                  value:
                      p.primaryGoal?.label(l10n) ?? p.primaryGoalLabel ?? '—',
                ),
                ProfileInfoRow(
                  icon: Icons.directions_run_rounded,
                  label: l10n.profileFieldActivityLevel,
                  value: p.activityLevel?.label(l10n) ?? '—',
                ),
                ProfileInfoRow(
                  icon: AppIcons.calendar,
                  label: l10n.profileFieldAvailableDays,
                  value: p.availableDays.isEmpty
                      ? '—'
                      : p.availableDays
                            .map((d) => ProfileWeekdays.short(l10n, d))
                            .join(' · '),
                ),
                if (p.minutesPerSession != null)
                  ProfileInfoRow(
                    icon: AppIcons.duration,
                    label: l10n.profileSessionLength,
                    value: l10n.profileMinutesShort(p.minutesPerSession!),
                  ),
                const SizedBox(height: TokensSpacing.s),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        _open(context, ProfilePaths.wellnessHistory),
                    icon: const Icon(Icons.show_chart_rounded),
                    label: Text(l10n.profileWellnessHistoryAction),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AcademicSummary extends StatelessWidget {
  const _AcademicSummary({required this.profile, required this.degrees});

  final AcademicProfile? profile;
  final List<UserDegree> degrees;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final p = profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.profileAcademicSection,
          actionLabel: p == null ? null : l10n.commonEdit,
          onAction: () => _open(context, ProfilePaths.editAcademic),
        ),
        if (p == null)
          _MissingCard(
            icon: Icons.school_rounded,
            color: context.palette.study,
            message: l10n.profileAcademicMissing,
            actionLabel: l10n.profileCompleteAction,
            onAction: () => _open(context, ProfilePaths.editAcademic),
          )
        else
          AppCard(
            child: Column(
              children: [
                ProfileInfoRow(
                  icon: Icons.account_balance_outlined,
                  label: l10n.profileFieldUniversity,
                  value: p.university ?? '—',
                ),
                ProfileInfoRow(
                  icon: Icons.school_outlined,
                  label: l10n.profileFieldDegree,
                  value: p.degree ?? '—',
                ),
                ProfileInfoRow(
                  icon: Icons.timeline_rounded,
                  label: l10n.profileFieldSemester,
                  value: p.semester == null
                      ? '—'
                      : l10n.profileSemesterValue(p.semester!),
                ),
                if (p.modality != null)
                  ProfileInfoRow(
                    icon: Icons.location_city_outlined,
                    label: l10n.profileFieldModality,
                    value: p.modality!.label(l10n),
                  ),
              ],
            ),
          ),
        const SizedBox(height: TokensSpacing.m),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFocusOutline(
                child: ListTile(
                  leading: Icon(
                    Icons.workspace_premium_outlined,
                    color: context.palette.study,
                  ),
                  title: Text(l10n.profileDegreesTitle),
                  subtitle: Text(
                    degrees.isEmpty
                        ? l10n.profileDegreesNone
                        : degrees.map((d) => d.degree.name).join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(AppIcons.next),
                  onTap: () => _open(context, ProfilePaths.degrees),
                ),
              ),
              const Divider(height: 1),
              AppFocusOutline(
                child: ListTile(
                  leading: Icon(
                    Icons.playlist_add_check_rounded,
                    color: context.palette.study,
                  ),
                  title: Text(l10n.profileSubjectsTitle),
                  trailing: const Icon(AppIcons.next),
                  onTap: () => _open(context, ProfilePaths.subjects),
                ),
              ),
              const Divider(height: 1),
              AppFocusOutline(
                child: ListTile(
                  leading: Icon(
                    Icons.upload_file_rounded,
                    color: context.palette.study,
                  ),
                  title: Text(l10n.profileEnrollmentEntry),
                  trailing: const Icon(AppIcons.next),
                  onTap: () => _open(context, ProfilePaths.enrollmentImport),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: TokensSpacing.xs),
        Text(value, style: context.textStyles.titleMedium),
        Text(
          label,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MissingCard extends StatelessWidget {
  const _MissingCard({
    required this.icon,
    required this.color,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: TokensSpacing.m),
          Expanded(child: Text(message, style: context.textStyles.bodyMedium)),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
