import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/together_enums.dart';
import '../../../../../domain/models/social/friendship.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../social/together/widgets/together_labels.dart';
import '../../../social/widgets/show_social_feedback.dart';
import '../../../social/widgets/user_tile.dart';
import '../../progress_routes.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/community_preview_card.dart';
import '../bloc/community_bloc.dart';

/// Tú › Comunidad (ADR 0061): lo social en un sitio. Arriba, la solicitud de
/// amistad que espera respuesta (con «Aceptar»); después los accesos a Mis
/// amigos, Buscar, Muro y Retos de otros; lo que está en marcha con amigos y
/// lo último del muro. Cada cosa abre su pantalla de siempre: aquí no se
/// repite ninguna.
class CommunityTab extends StatelessWidget {
  const CommunityTab({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<CommunityBloc>()..add(const CommunityEvent.started()),
    child: const _CommunityView(),
  );
}

class _CommunityView extends StatelessWidget {
  const _CommunityView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommunityBloc, CommunityState>(
      listenWhen: (_, current) => current.feedback != null,
      listener: (context, state) =>
          showSocialFeedback(context, state.feedback!),
      builder: (context, state) => switch (state.status) {
        CommunityStatus.loading => const _CommunitySkeleton(),
        CommunityStatus.failure => AppErrorView(
          error: state.error!,
          onRetry: () =>
              context.read<CommunityBloc>().add(const CommunityEvent.started()),
        ),
        CommunityStatus.ready => RefreshIndicator(
          onRefresh: () async {
            final bloc = context.read<CommunityBloc>()
              ..add(const CommunityEvent.refreshed());
            // Basta con la siguiente lectura (lista o aviso de error).
            await bloc.stream.first;
          },
          child: _CommunityBody(state: state),
        ),
      },
    );
  }
}

/// Abre una pantalla completa y vuelve a leer al volver (pudo cambiar algo).
Future<void> _open(BuildContext context, String path) async {
  final bloc = context.read<CommunityBloc>();
  await context.push<Object?>(path);
  if (!bloc.isClosed) bloc.add(const CommunityEvent.refreshed());
}

class _CommunityBody extends StatelessWidget {
  const _CommunityBody({required this.state});

  final CommunityState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        AppContentWidth.reading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.requestsTotal > 0 && state.requests.isNotEmpty) ...[
                _RequestsCard(state: state),
                const SizedBox(height: TokensSpacing.m),
              ],
              AppShortcutGrid(
                tiles: [
                  AppShortcutTile(
                    icon: AppIcons.friends,
                    label: l10n.progressCommunityFriendsTile,
                    detail: l10n.progressCommunityFriendsCount(
                      state.friendsTotal,
                    ),
                    tone: AppTileTone.neutral,
                    onTap: () => _open(context, ProgressExternalPaths.friends),
                  ),
                  AppShortcutTile(
                    icon: AppIcons.search,
                    label: l10n.progressCommunitySearchTile,
                    semanticsLabel: l10n.progressCommunitySearchSemantics,
                    detail: l10n.progressCommunitySearchDetail,
                    tone: AppTileTone.neutral,
                    onTap: () =>
                        _open(context, ProgressExternalPaths.friendSearch),
                  ),
                  AppShortcutTile(
                    icon: AppIcons.community,
                    label: l10n.progressCommunityWallTile,
                    detail: l10n.progressCommunityWallDetail,
                    tone: AppTileTone.neutral,
                    onTap: () =>
                        _open(context, ProgressExternalPaths.socialWall),
                  ),
                  AppShortcutTile(
                    icon: AppIcons.communityChallenges,
                    label: l10n.progressCommunityOthersChallengesTile,
                    detail: l10n.progressCommunityOthersChallengesDetail,
                    tone: AppTileTone.neutral,
                    onTap: () => _open(
                      context,
                      ProgressExternalPaths.communityChallenges,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TokensSpacing.l),
              _TogetherSection(
                loaded: state.together != null,
                items: state.togetherNow,
              ),
              const SizedBox(height: TokensSpacing.l),
              CommunityPreviewCard(
                posts: state.posts,
                onOpenWall: () =>
                    _open(context, ProgressExternalPaths.socialWall),
                onOpenPost: (post) =>
                    _open(context, ProgressExternalPaths.socialPost(post.id)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Solicitudes de amistad recibidas: la primera se contesta aquí y el resto
/// en Amigos › Recibidas.
class _RequestsCard extends StatelessWidget {
  const _RequestsCard({required this.state});

  final CommunityState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final hidden = state.requestsTotal > state.requests.length;
    final colors = context.colors;
    // Destacada sobre el color terciario (la maqueta): el texto va en su
    // pareja «on» para el contraste AA; la fila de la persona, en su tarjeta.
    return AppCard(
      color: colors.tertiaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.progressCommunityRequestsTitle(state.requestsTotal),
              style: context.textStyles.titleMedium?.copyWith(
                color: colors.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          for (final request in state.requests)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.s),
              child: _RequestTile(
                request: request,
                busy: state.busyIds.contains(request.id),
              ),
            ),
          if (hidden)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                icon: const Icon(AppIcons.next),
                label: Text(
                  l10n.progressCommunitySeeAllRequests(state.requestsTotal),
                ),
                onPressed: () =>
                    _open(context, ProgressExternalPaths.friendRequests),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.busy});

  final Friendship request;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<CommunityBloc>();
    final user = request.user;
    return UserTile(
      name: user.fullName,
      avatarUrl: user.avatarUrl,
      level: user.level,
      subtitle: l10n.socialRequestReceivedHint,
      onTap: () => _open(context, ProgressExternalPaths.user(user.id)),
      trailing: busy
          ? const BusyIndicator()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rechazar, aparte y con borde: no es la acción principal.
                IconButton.outlined(
                  tooltip: l10n.progressCommunityRejectNamed(user.fullName),
                  icon: const Icon(AppIcons.close),
                  onPressed: () =>
                      bloc.add(CommunityEvent.requestRejected(request.id)),
                ),
                const SizedBox(width: TokensSpacing.s),
                FilledButton(
                  onPressed: () =>
                      bloc.add(CommunityEvent.requestAccepted(request.id)),
                  // Se ve «Aceptar»; el lector oye a quién (como «Rechazar»).
                  child: Text(
                    l10n.socialAccept,
                    semanticsLabel: l10n.progressCommunityAcceptNamed(
                      user.fullName,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// «Con amigos ahora»: lo que está en marcha (salas, entrenos, retos y
/// rachas) en filas que abren cada cosa; «Ver todo» abre «Con amigos».
class _TogetherSection extends StatelessWidget {
  const _TogetherSection({required this.loaded, required this.items});

  /// «Con amigos» se pudo leer.
  final bool loaded;

  /// Lo que está en marcha, ya ordenado ([CommunityState.togetherNow]).
  final List<TogetherNowItem> items;

  /// Filas a la vista: el resto está en «Con amigos».
  static const _maxRows = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final rows = [for (final item in items.take(_maxRows)) _row(context, item)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.xs,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.progressCommunityTogetherTitle,
                style: context.textStyles.titleMedium,
              ),
            ),
            OutlinedButton(
              onPressed: () => _open(context, ProgressExternalPaths.together),
              child: Text(l10n.commonSeeAll),
            ),
          ],
        ),
        const SizedBox(height: TokensSpacing.s),
        if (!loaded)
          AppCard(
            child: InlineNotice(
              icon: AppIcons.unavailable,
              message: l10n.progressSectionUnavailable,
            ),
          )
        else if (rows.isEmpty)
          AppCard(
            child: Text(
              l10n.progressCommunityTogetherEmpty,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, row) in rows.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  AppFocusOutline(
                    child: ListTile(
                      leading: AppTintedIcon(icon: row.icon, tone: row.tone),
                      title: Text(row.title),
                      subtitle: row.detail == null ? null : Text(row.detail!),
                      trailing: const Icon(AppIcons.next),
                      onTap: () => _open(context, row.path),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  /// Texto, icono y destino de cada fila (el orden lo da el estado).
  static _TogetherRow _row(BuildContext context, TogetherNowItem item) {
    final l10n = context.localizations;
    return switch (item) {
      TogetherNowInvitations(:final count) => _TogetherRow(
        icon: AppIcons.invitation,
        tone: AppTileTone.tertiary,
        title: l10n.progressCommunityTogetherInvitations(count),
        detail: l10n.progressCommunityTogetherInvitationsDetail,
        path: ProgressExternalPaths.together,
      ),
      TogetherNowStudyRoom(:final room) => _TogetherRow(
        icon: AppIcons.focusTimer,
        tone: AppTileTone.tertiary,
        title: l10n.togetherStudyTitle,
        detail: switch (room.phase) {
          StudyRoomPhase.waiting => l10n.togetherStudyWaiting,
          StudyRoomPhase.focus => l10n.togetherStudyFocusRound(
            room.round,
            room.rounds,
          ),
          _ => l10n.togetherStudyBreakThen(room.round + 1, room.rounds),
        },
        path: ProgressExternalPaths.togetherStudyRoom(room.id),
      ),
      TogetherNowWorkout(:final workout) => _TogetherRow(
        icon: AppIcons.routine,
        tone: AppTileTone.secondary,
        title: workout.routineName ?? l10n.togetherWorkoutTitle,
        detail: workout.routineName == null ? null : l10n.togetherWorkoutTitle,
        path: ProgressExternalPaths.togetherWorkout(workout.id),
      ),
      TogetherNowChallenge(:final challenge) => _TogetherRow(
        icon: AppIcons.challenge,
        tone: AppTileTone.accent,
        title: challenge.title,
        detail: l10n.togetherChallengeUntil(
          DateFormat.MMMEd(l10n.localeName).format(challenge.endAt),
        ),
        path: ProgressExternalPaths.togetherChallenge(challenge.id),
      ),
      TogetherNowStreak(:final streak) => _TogetherRow(
        icon: AppIcons.streak,
        tone: AppTileTone.accent,
        title: l10n.togetherStreakWith(
          togetherName(context, streak.friend.name),
          streak.days,
        ),
        path: ProgressExternalPaths.together,
      ),
    };
  }
}

/// Una fila de «Con amigos ahora»: qué es, cómo va y adónde lleva. El tono
/// sigue la maqueta: lo social y estudiar en violeta, entrenar en lima, retos
/// y rachas en naranja (el texto dice qué es: el color es decorativo).
class _TogetherRow {
  const _TogetherRow({
    required this.icon,
    required this.tone,
    required this.title,
    required this.path,
    this.detail,
  });

  final IconData icon;
  final AppTileTone tone;
  final String title;
  final String? detail;
  final String path;
}

class _CommunitySkeleton extends StatelessWidget {
  const _CommunitySkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonGroup(
      child: Padding(
        padding: EdgeInsets.all(TokensSpacing.m),
        child: Column(
          children: [
            AppSkeleton(height: TokensSize.skeletonRow),
            SizedBox(height: TokensSpacing.m),
            AppSkeleton(height: TokensSize.skeletonCardTall),
            SizedBox(height: TokensSpacing.l),
            AppSkeleton(height: TokensSize.skeletonCard),
          ],
        ),
      ),
    );
  }
}
