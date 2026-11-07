import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/friendship_relation.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/models/social/public_profile.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../social_routes.dart';
import '../../widgets/post_card.dart';
import '../../widgets/social_dialogs.dart';
import '../../widgets/social_feedback.dart';
import '../../widgets/social_layout.dart';
import '../bloc/user_profile_bloc.dart';
import 'public_badges_section.dart';

/// Perfil público de un usuario (`/social/users/:userId`).
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<UserProfileBloc>()..add(UserProfileEvent.started(userId)),
      child: const _UserProfileView(),
    );
  }
}

class _UserProfileView extends StatelessWidget {
  const _UserProfileView();

  /// Apuntes que comparte conmigo: solo si hay alguno (o si falló la carga).
  List<Widget> _sharedNotes(BuildContext context, UserProfileState state) {
    final l10n = context.localizations;
    if (state.notes.isEmpty && state.notesError == null) return const [];
    return [
      const SizedBox(height: TokensSpacing.l),
      SocialContentWidth(
        child: AppSectionHeader(
          title: l10n.socialProfileNotes,
          actionLabel: state.hasMoreNotes ? l10n.socialProfileNotesAll : null,
          onAction: () =>
              context.push(SocialExternalPaths.sharedNotesBy(state.userId)),
        ),
      ),
      if (state.notes.isEmpty)
        AppErrorView(
          error: state.notesError!,
          onRetry: () => context.read<UserProfileBloc>().add(
            const UserProfileEvent.refreshed(),
          ),
        ),
      for (final note in state.notes) ...[
        SocialContentWidth(child: _SharedNoteTile(note: note)),
        const SizedBox(height: TokensSpacing.s),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<UserProfileBloc>();
    return BlocConsumer<UserProfileBloc, UserProfileState>(
      listenWhen: (_, current) => current.feedback != null,
      listener: (context, state) =>
          showSocialFeedback(context, state.feedback!),
      builder: (context, state) => Scaffold(
        appBar: AppPageBar.reading(
          title: Text(state.profile?.fullName ?? l10n.socialProfileTitle),
        ),
        body: switch (state.status) {
          SocialLoadStatus.loading => const SocialListSkeleton(count: 3),
          SocialLoadStatus.failure => AppErrorView(
            error: state.error!,
            onRetry: () => bloc.add(UserProfileEvent.started(state.userId)),
          ),
          SocialLoadStatus.loaded => RefreshIndicator(
            onRefresh: () async {
              bloc.add(const UserProfileEvent.refreshed());
              await bloc.stream
                  .skipWhile((s) => !s.refreshing)
                  .firstWhere((s) => !s.refreshing);
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) => onScrollNearEnd(
                n,
                () => bloc.add(const UserProfileEvent.nextPostsRequested()),
              ),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(TokensSpacing.m),
                children: [
                  SocialContentWidth(
                    child: _ProfileHeader(
                      profile: state.profile!,
                      busy: state.busy,
                    ),
                  ),
                  if (!state.profile!.restricted) ...[
                    PublicBadgesSection(profile: state.profile!),
                    ..._sharedNotes(context, state),
                  ],
                  const SizedBox(height: TokensSpacing.l),
                  SocialContentWidth(
                    child: AppSectionHeader(title: l10n.socialProfilePosts),
                  ),
                  if (state.posts.isEmpty)
                    state.postsError != null
                        ? AppErrorView(
                            error: state.postsError!,
                            onRetry: () =>
                                bloc.add(const UserProfileEvent.refreshed()),
                          )
                        : AppEmptyState(
                            icon: Icons.article_outlined,
                            title: l10n.socialProfilePostsEmpty,
                          ),
                  for (final post in state.posts) ...[
                    SocialContentWidth(
                      child: PostCard(
                        key: ValueKey(post.id),
                        post: post,
                        onLike: () =>
                            bloc.add(UserProfileEvent.likeToggled(post.id)),
                        onOpen: () async {
                          await context.push<void>(SocialPaths.post(post.id));
                          bloc.add(const UserProfileEvent.refreshed());
                        },
                        onLinkTap: (route) =>
                            SocialExternalPaths.opensInTab(route)
                            ? context.go(route)
                            : context.push<void>(route),
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.m),
                  ],
                  if (state.loadingMorePosts) const LoadMoreIndicator(),
                ],
              ),
            ),
          ),
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.busy});

  final PublicProfile profile;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final myId = context.select<SessionBloc, String?>((bloc) {
      final session = bloc.state;
      return session is SessionAuthenticatedState ? session.account.id : null;
    });
    final isMe = myId == profile.id;
    final level = profile.level;
    // Banda de color de marca tras la mitad superior del avatar: da presencia
    // a la cabecera sin degradados ni foto.
    final band = Color.alphaBlend(
      context.colors.primary.withValues(alpha: AppPill.tintAlpha),
      context.colors.surface,
    );
    return AppCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // Hasta el centro del avatar (relleno + aro + radio).
            height:
                TokensSpacing.l + TokensSpacing.xs + TokensSize.medallion / 2,
            child: ColoredBox(color: band),
          ),
          Padding(
            padding: const EdgeInsets.all(TokensSpacing.l),
            child: _headerContent(context, isMe: isMe, level: level),
          ),
        ],
      ),
    );
  }

  Widget _headerContent(
    BuildContext context, {
    required bool isMe,
    required int? level,
  }) {
    final l10n = context.localizations;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: context.colors.surface,
              width: TokensSpacing.xs,
            ),
          ),
          child: AppAvatar(
            name: profile.fullName,
            imageUrl: profile.avatarUrl,
            radius: TokensSize.medallion / 2,
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        Text(
          profile.fullName,
          style: context.textStyles.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (level != null) ...[
          const SizedBox(height: TokensSpacing.s),
          AppPill(
            icon: Icons.military_tech_rounded,
            label: l10n.commonLevel(level),
            color: context.palette.accent,
          ),
        ],
        const SizedBox(height: TokensSpacing.m),
        if (profile.restricted)
          _RestrictedNotice(relation: profile.relation)
        else
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  icon: Icons.local_fire_department_rounded,
                  color: context.palette.streak,
                  value: '${profile.streak ?? 0}',
                  label: l10n.socialProfileStreak,
                  bare: true,
                ),
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: AppMetricTile(
                  icon: Icons.article_rounded,
                  color: context.colors.primary,
                  value: '${profile.postsCount ?? 0}',
                  label: l10n.socialProfilePostsCount,
                  bare: true,
                ),
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: AppMetricTile(
                  icon: Icons.people_alt_rounded,
                  color: context.colors.secondary,
                  value: '${profile.friendsCount ?? 0}',
                  label: l10n.socialProfileFriendsCount,
                  bare: true,
                ),
              ),
            ],
          ),
        if (isMe) ...[
          const SizedBox(height: TokensSpacing.m),
          Text(
            l10n.socialProfileIsMe,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ] else ...[
          const SizedBox(height: TokensSpacing.m),
          _RelationActions(profile: profile, busy: busy),
        ],
      ],
    );
  }
}

/// Apunte compartido del perfil: título, extracto y asignatura; abre su
/// lectura en el módulo académico.
class _SharedNoteTile extends StatelessWidget {
  const _SharedNoteTile({required this.note});

  final SharedNoteSummary note;

  @override
  Widget build(BuildContext context) {
    final subject = note.catalogSubjectName;
    return AppCard(
      onTap: () => context.push(SocialExternalPaths.sharedNote(note.id)),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: context.colors.tertiary),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall,
                ),
                if (note.excerpt.isNotEmpty)
                  Text(
                    note.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                if (subject != null && subject.isNotEmpty) ...[
                  const SizedBox(height: TokensSpacing.xs),
                  AppPill(
                    label: subject,
                    color: context.colors.tertiary,
                    icon: Icons.school_outlined,
                  ),
                ],
              ],
            ),
          ),
          const Icon(AppIcons.next),
        ],
      ),
    );
  }
}

class _RestrictedNotice extends StatelessWidget {
  const _RestrictedNotice({required this.relation});

  final FriendshipRelation relation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Container(
      padding: const EdgeInsets.all(TokensSpacing.m),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(TokensRadius.m),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Text(
              relation == FriendshipRelation.blocked
                  ? l10n.socialProfileBlockedNotice
                  : l10n.socialProfileRestricted,
              style: context.textStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationActions extends StatelessWidget {
  const _RelationActions({required this.profile, required this.busy});

  final PublicProfile profile;
  final bool busy;

  Future<void> _run(
    BuildContext context,
    ProfileRelationAction action, {
    bool confirm = false,
  }) async {
    final l10n = context.localizations;
    final bloc = context.read<UserProfileBloc>();
    if (confirm) {
      final name = profile.fullName;
      final (title, message, label, destructive) = switch (action) {
        ProfileRelationAction.removeFriend => (
          l10n.socialRemoveFriendTitle,
          l10n.socialRemoveFriendMessage(name),
          l10n.socialRemoveFriend,
          true,
        ),
        ProfileRelationAction.block => (
          l10n.socialBlockTitle,
          l10n.socialBlockMessage(name),
          l10n.socialBlock,
          true,
        ),
        _ => (
          l10n.socialUnblockTitle,
          l10n.socialUnblockMessage(name),
          l10n.socialUnblock,
          false,
        ),
      };
      final ok = await confirmSocialAction(
        context,
        title: title,
        message: message,
        confirmLabel: label,
        destructive: destructive,
      );
      if (!ok) return;
    }
    bloc.add(UserProfileEvent.relationActionRequested(action));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    if (busy) return const Center(child: CircularProgressIndicator());
    final primary = switch (profile.relation) {
      FriendshipRelation.none => [
        Expanded(
          child: AppPrimaryButton(
            label: l10n.socialAddFriend,
            icon: Icons.person_add_alt_1_rounded,
            onPressed: () => _run(context, ProfileRelationAction.sendRequest),
          ),
        ),
      ],
      FriendshipRelation.requestSent => [
        Expanded(
          child: AppSecondaryButton(
            label: l10n.socialCancelRequest,
            icon: const Icon(Icons.schedule_send_outlined),
            onPressed: () => _run(context, ProfileRelationAction.cancelRequest),
          ),
        ),
      ],
      FriendshipRelation.requestReceived => [
        Expanded(
          child: AppPrimaryButton(
            label: l10n.socialAccept,
            onPressed: () => _run(context, ProfileRelationAction.accept),
          ),
        ),
        const SizedBox(width: TokensSpacing.s),
        Expanded(
          child: AppSecondaryButton(
            label: l10n.socialReject,
            onPressed: () => _run(context, ProfileRelationAction.reject),
          ),
        ),
      ],
      FriendshipRelation.friends => [
        Expanded(
          child: AppSecondaryButton(
            label: l10n.socialRemoveFriend,
            icon: const Icon(Icons.person_remove_outlined),
            onPressed: () => _run(
              context,
              ProfileRelationAction.removeFriend,
              confirm: true,
            ),
          ),
        ),
      ],
      FriendshipRelation.blocked => [
        Expanded(
          child: AppSecondaryButton(
            label: l10n.socialUnblock,
            icon: const Icon(Icons.lock_open_rounded),
            onPressed: () =>
                _run(context, ProfileRelationAction.unblock, confirm: true),
          ),
        ),
      ],
    };
    return Column(
      children: [
        if (profile.relation == FriendshipRelation.friends)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensSpacing.s),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: TokensSize.iconS,
                  color: context.palette.success,
                ),
                const SizedBox(width: TokensSpacing.xs),
                Text(
                  l10n.socialRelationFriends,
                  style: context.textStyles.labelLarge,
                ),
              ],
            ),
          ),
        if (profile.relation == FriendshipRelation.requestReceived)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensSpacing.s),
            child: Text(
              l10n.socialRelationRequestReceived,
              style: context.textStyles.bodyMedium,
            ),
          ),
        Row(children: primary),
        // Antes en un menú de tres puntos con una sola acción: ahora a la
        // vista y con texto, en su propia fila (cabe con el texto al 200 %).
        if (profile.relation != FriendshipRelation.blocked)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: context.colors.error,
              ),
              onPressed: () =>
                  _run(context, ProfileRelationAction.block, confirm: true),
              icon: const Icon(AppIcons.block),
              label: Text(l10n.socialBlock),
            ),
          ),
      ],
    );
  }
}
