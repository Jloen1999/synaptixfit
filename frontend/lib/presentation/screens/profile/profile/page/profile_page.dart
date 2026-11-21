import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/profile/profile_summary.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../profile_routes.dart';
import '../../widgets/profile_labels.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/profile_bloc.dart';
import 'profile_detail_pages.dart';

/// Perfil del usuario (`/profile`, ADR 0061): la cuenta en una tarjeta
/// compacta y seis tarjetitas que llevan a cada parte (Amigos, Muro, Cómo me
/// ven, Físico, Académico y Ajustes). Físico y Académico solo salen si la
/// persona hace deporte o estudia. Se abre desde la cabecera de «Tú» y desde
/// el avatar de Inicio.
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
        leading: const AppBackButton(fallback: ProfilePaths.you),
        title: Text(l10n.profileTitle),
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

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonGroup(
      child: ProfileScrollBody(
        physics: NeverScrollableScrollPhysics(),
        children: [
          AppSkeleton(height: TokensSize.skeletonRow),
          SizedBox(height: TokensSpacing.m),
          AppSkeleton(height: TokensSize.skeletonPanel),
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
        _AccountCard(account: account),
        const SizedBox(height: TokensSpacing.m),
        _ProfileTiles(
          account: account,
          summary: summary,
          pendingRequests: pendingRequests,
        ),
        if (!summary.onboarding.completed) ...[
          const SizedBox(height: TokensSpacing.m),
          AppCard(
            color: context.colors.primaryContainer,
            onTap: () => openProfileScreen(context, ProfilePaths.onboarding),
            child: Row(
              children: [
                Icon(
                  AppIcons.onboarding,
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
          ProfileMissingCard(
            icon: AppIcons.birthday,
            color: context.palette.accent,
            message: l10n.profileBirthDateSuggestion,
            actionLabel: l10n.profileBirthDateAdd,
            onAction: () =>
                openProfileScreen(context, ProfilePaths.editAccount),
          ),
        ],
        if (account.isAdmin) ...[
          const SizedBox(height: TokensSpacing.m),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppFocusOutline(
              child: ListTile(
                leading: Icon(AppIcons.admin, color: context.colors.primary),
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

/// La cuenta, compacta: foto, nombre, correo y visibilidad (cada uno en su
/// línea, sin cortarse), la racha (abre Tú › Resumen) y «Editar» (botón con
/// borde). Si no cabe al lado (texto grande o poco ancho), «Editar» baja.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final muted = context.textStyles.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final edit = AppSecondaryButton(
      label: l10n.commonEdit,
      icon: const Icon(AppIcons.edit),
      onPressed: () => openProfileScreen(context, ProfilePaths.editAccount),
    );
    final identity = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
          name: account.fullName,
          imageUrl: account.avatarUrl,
          radius: TokensSize.emblem / 2,
        ),
        const SizedBox(width: TokensSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account.fullName, style: context.textStyles.titleMedium),
              Text(account.email, style: muted),
              Text(account.privacy.label(l10n), style: muted),
              const SizedBox(height: TokensSpacing.xs),
              // Nivel y XP se ven en «Tú» (ADR 0038); aquí, solo la racha,
              // que lleva a ellos (pestaña: con `go`).
              ActionChip(
                avatar: Icon(AppIcons.streak, color: context.palette.streak),
                label: Text(l10n.profileStreakDays(account.streak)),
                tooltip: l10n.profileStreakOpenHint,
                onPressed: () => context.go(ProfilePaths.you),
              ),
            ],
          ),
        ),
      ],
    );
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              context.largeText ||
              constraints.maxWidth <
                  context.scaled(TokensLayout.cardActionsInlineMin);
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: TokensSpacing.s),
                Align(alignment: AlignmentDirectional.centerStart, child: edit),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: identity),
              const SizedBox(width: TokensSpacing.s),
              edit,
            ],
          );
        },
      ),
    );
  }
}

/// Las seis tarjetitas del perfil. Amigos y Muro también están en
/// Tú › Comunidad; aquí siguen para quien entra por su foto.
class _ProfileTiles extends StatelessWidget {
  const _ProfileTiles({
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
    final wellness = summary.wellness;
    final academic = summary.academic;
    final number = NumberFormat('0.#');
    final body = [
      if (wellness?.weightKg case final kg?)
        l10n.profileKgValue(number.format(kg)),
      if (wellness?.heightCm case final cm?)
        l10n.profileCmValue(number.format(cm)),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.profileSectionsLabel,
      child: AppShortcutGrid(
        tiles: [
          AppShortcutTile(
            icon: AppIcons.friends,
            label: l10n.profileFriends,
            detail: pendingRequests > 0
                ? l10n.profileFriendsPending(pendingRequests)
                : null,
            badgeCount: pendingRequests,
            onTap: () => openProfileScreen(
              context,
              pendingRequests > 0
                  ? ProfilePaths.friendRequests
                  : ProfilePaths.friends,
            ),
          ),
          AppShortcutTile(
            icon: AppIcons.community,
            label: l10n.profileWall,
            detail: l10n.profileWallDetail,
            onTap: () => openProfileScreen(context, ProfilePaths.community),
          ),
          AppShortcutTile(
            icon: AppIcons.preview,
            label: l10n.profilePublicProfileTile,
            detail: account.privacy.label(l10n),
            onTap: () => openProfileScreen(
              context,
              ProfilePaths.publicProfile(account.id),
            ),
          ),
          if (account.usageFocus.includesFitness)
            AppShortcutTile(
              icon: AppIcons.bodyWeight,
              label: l10n.profilePhysicalTile,
              // Sin peso ni altura también falta lo principal.
              detail: body.isEmpty ? l10n.profileTileMissing : body.join(' · '),
              onTap: () => openProfileScreen(context, ProfilePaths.physical),
            ),
          if (account.usageFocus.includesAcademic)
            AppShortcutTile(
              icon: AppIcons.subject,
              label: l10n.profileAcademicTile,
              detail: academic == null
                  ? l10n.profileTileMissing
                  : academic.degree,
              onTap: () => openProfileScreen(context, ProfilePaths.studies),
            ),
          AppShortcutTile(
            icon: AppIcons.settings,
            label: l10n.profileSettingsTitle,
            detail: l10n.profileSettingsDetail,
            onTap: () => openProfileScreen(context, ProfilePaths.settings),
          ),
        ],
      ),
    );
  }
}
