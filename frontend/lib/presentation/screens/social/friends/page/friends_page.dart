import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/friendship_list_kind.dart';
import '../../../../../domain/enums/friendship_relation.dart';
import '../../../../../domain/models/social/friendship.dart';
import '../../../../../domain/models/social/user_card.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../social_routes.dart';
import '../../widgets/social_dialogs.dart';
import '../../widgets/social_feedback.dart';
import '../../widgets/social_layout.dart';
import '../../widgets/user_tile.dart';
import '../bloc/friends_bloc.dart';

/// Amistades (`/social/friends`) y solicitudes (`/social/friends/requests`,
/// que abre directamente la pestaña de recibidas).
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key, this.initialTab = FriendshipListKind.friends});

  final FriendshipListKind initialTab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FriendsBloc>()..add(const FriendsEvent.started()),
      child: DefaultTabController(
        length: FriendshipListKind.values.length,
        initialIndex: initialTab.index,
        child: const _FriendsView(),
      ),
    );
  }
}

class _FriendsView extends StatefulWidget {
  const _FriendsView();

  @override
  State<_FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<_FriendsView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    context.read<FriendsBloc>().add(const FriendsEvent.queryChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocListener<FriendsBloc, FriendsState>(
      listenWhen: (_, current) => current.feedback != null,
      listener: (context, state) =>
          showSocialFeedback(context, state.feedback!),
      child: Scaffold(
        appBar: AppPageBar.reading(title: Text(l10n.socialFriendsTitle)),
        body: SocialContentWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  TokensSpacing.s,
                  TokensSpacing.m,
                  TokensSpacing.s,
                ),
                child: ListenableBuilder(
                  listenable: _search,
                  builder: (context, _) => TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => context.read<FriendsBloc>().add(
                      FriendsEvent.queryChanged(value),
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.socialSearchUsersHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.socialSearchClear,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: _clearSearch,
                            ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: BlocSelector<FriendsBloc, FriendsState, bool>(
                  selector: (state) => state.searching,
                  builder: (context, searching) =>
                      searching ? const _SearchResults() : const _Tabs(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  String _label(BuildContext context, FriendshipListKind kind) {
    final l10n = context.localizations;
    return switch (kind) {
      FriendshipListKind.friends => l10n.socialTabFriends,
      FriendshipListKind.received => l10n.socialTabReceived,
      FriendshipListKind.sent => l10n.socialTabSent,
      FriendshipListKind.blocked => l10n.socialTabBlocked,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocSelector<FriendsBloc, FriendsState, int>(
          selector: (state) =>
              state.section(FriendshipListKind.received).items.length,
          builder: (context, received) => TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final kind in FriendshipListKind.values)
                Tab(
                  child: kind == FriendshipListKind.received && received > 0
                      ? Badge(
                          label: Text('$received'),
                          offset: const Offset(14, -4),
                          child: Text(_label(context, kind)),
                        )
                      : Text(_label(context, kind)),
                ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              for (final kind in FriendshipListKind.values)
                _FriendshipList(kind: kind),
            ],
          ),
        ),
      ],
    );
  }
}

class _FriendshipList extends StatelessWidget {
  const _FriendshipList({required this.kind});

  final FriendshipListKind kind;

  ({IconData icon, String title, String message}) _empty(BuildContext context) {
    final l10n = context.localizations;
    return switch (kind) {
      FriendshipListKind.friends => (
        icon: Icons.people_outline_rounded,
        title: l10n.socialFriendsEmptyTitle,
        message: l10n.socialFriendsEmptyMessage,
      ),
      FriendshipListKind.received => (
        icon: Icons.mark_email_unread_outlined,
        title: l10n.socialReceivedEmptyTitle,
        message: l10n.socialReceivedEmptyMessage,
      ),
      FriendshipListKind.sent => (
        icon: Icons.send_outlined,
        title: l10n.socialSentEmptyTitle,
        message: l10n.socialSentEmptyMessage,
      ),
      FriendshipListKind.blocked => (
        icon: Icons.block_outlined,
        title: l10n.socialBlockedEmptyTitle,
        message: l10n.socialBlockedEmptyMessage,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FriendsBloc>();
    return BlocBuilder<FriendsBloc, FriendsState>(
      buildWhen: (previous, current) =>
          previous.section(kind) != current.section(kind) ||
          previous.busyIds != current.busyIds,
      builder: (context, state) {
        final section = state.section(kind);
        return switch (section.status) {
          SocialLoadStatus.loading => const SocialListSkeleton(
            itemHeight: 64,
            count: 6,
          ),
          SocialLoadStatus.failure => AppErrorView(
            error: section.error!,
            onRetry: () => bloc.add(FriendsEvent.sectionRefreshed(kind)),
          ),
          SocialLoadStatus.loaded => RefreshIndicator(
            onRefresh: () async {
              bloc.add(FriendsEvent.sectionRefreshed(kind));
              await bloc.stream
                  .skipWhile((s) => !s.section(kind).refreshing)
                  .firstWhere((s) => !s.section(kind).refreshing);
            },
            child: section.items.isEmpty
                ? _ScrollableEmpty(empty: _empty(context))
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) => onScrollNearEnd(
                      n,
                      () => bloc.add(FriendsEvent.nextPageRequested(kind)),
                    ),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(TokensSpacing.m),
                      itemCount:
                          section.items.length + (section.loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: TokensSpacing.s),
                      itemBuilder: (context, index) {
                        if (index >= section.items.length) {
                          return const LoadMoreIndicator();
                        }
                        final friendship = section.items[index];
                        return _FriendshipTile(
                          friendship: friendship,
                          kind: kind,
                          busy: state.busyIds.contains(friendship.id),
                        );
                      },
                    ),
                  ),
          ),
        };
      },
    );
  }
}

class _ScrollableEmpty extends StatelessWidget {
  const _ScrollableEmpty({required this.empty});

  final ({IconData icon, String title, String message}) empty;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: AppEmptyState(
          icon: empty.icon,
          title: empty.title,
          message: empty.message,
        ),
      ),
    ),
  );
}

class _FriendshipTile extends StatelessWidget {
  const _FriendshipTile({
    required this.friendship,
    required this.kind,
    required this.busy,
  });

  final Friendship friendship;
  final FriendshipListKind kind;
  final bool busy;

  Future<void> _remove(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<FriendsBloc>();
    final ok = await confirmSocialAction(
      context,
      title: l10n.socialRemoveFriendTitle,
      message: l10n.socialRemoveFriendMessage(friendship.user.fullName),
      confirmLabel: l10n.socialRemoveFriend,
    );
    if (ok) {
      bloc.add(
        FriendsEvent.removed(
          friendshipId: friendship.id,
          message: SocialMessage.friendRemoved,
        ),
      );
    }
  }

  Future<void> _unblock(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<FriendsBloc>();
    final ok = await confirmSocialAction(
      context,
      title: l10n.socialUnblockTitle,
      message: l10n.socialUnblockMessage(friendship.user.fullName),
      confirmLabel: l10n.socialUnblock,
      destructive: false,
    );
    if (ok) {
      bloc.add(
        FriendsEvent.removed(
          friendshipId: friendship.id,
          message: SocialMessage.userUnblocked,
        ),
      );
    }
  }

  Widget _actions(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<FriendsBloc>();
    if (busy) return const BusyIndicator();
    return switch (kind) {
      FriendshipListKind.friends => IconButton(
        tooltip: l10n.socialRemoveFriend,
        icon: const Icon(Icons.person_remove_outlined),
        onPressed: () => _remove(context),
      ),
      FriendshipListKind.received => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.socialReject,
            icon: const Icon(Icons.close_rounded),
            onPressed: () =>
                bloc.add(FriendsEvent.requestRejected(friendship.id)),
          ),
          FilledButton.tonal(
            onPressed: () =>
                bloc.add(FriendsEvent.requestAccepted(friendship.id)),
            child: Text(l10n.socialAccept),
          ),
        ],
      ),
      FriendshipListKind.sent => TextButton(
        onPressed: () => bloc.add(
          FriendsEvent.removed(
            friendshipId: friendship.id,
            message: SocialMessage.requestCancelled,
          ),
        ),
        child: Text(l10n.socialCancelRequest),
      ),
      FriendshipListKind.blocked => TextButton(
        onPressed: () => _unblock(context),
        child: Text(l10n.socialUnblock),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = friendship.user;
    return UserTile(
      name: user.fullName,
      avatarUrl: user.avatarUrl,
      level: user.level,
      trailing: _actions(context),
      onTap: kind == FriendshipListKind.blocked
          ? null
          : () => _openProfileAndRefresh(context, user.id),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<FriendsBloc, FriendsState>(
      buildWhen: (previous, current) =>
          previous.searchStatus != current.searchStatus ||
          previous.results != current.results ||
          previous.busyIds != current.busyIds,
      builder: (context, state) => switch (state.searchStatus) {
        UserSearchStatus.idle || UserSearchStatus.loading =>
          const SocialListSkeleton(itemHeight: 64, count: 4),
        UserSearchStatus.failure => AppErrorView(error: state.searchError!),
        UserSearchStatus.loaded when state.results.isEmpty => AppEmptyState(
          icon: Icons.person_search_outlined,
          title: l10n.socialSearchEmptyTitle,
          message: l10n.socialSearchEmptyMessage(state.query),
        ),
        UserSearchStatus.loaded => ListView.separated(
          padding: const EdgeInsets.all(TokensSpacing.m),
          itemCount: state.results.length,
          separatorBuilder: (_, _) => const SizedBox(height: TokensSpacing.s),
          itemBuilder: (context, index) {
            final user = state.results[index];
            return _SearchResultTile(
              user: user,
              busy:
                  state.busyIds.contains(user.id) ||
                  (user.friendshipId != null &&
                      state.busyIds.contains(user.friendshipId)),
            );
          },
        ),
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.user, required this.busy});

  final UserCard user;
  final bool busy;

  Widget _action(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<FriendsBloc>();
    final friendshipId = user.friendshipId;
    if (busy) return const BusyIndicator();
    return switch (user.relation) {
      FriendshipRelation.none => FilledButton.tonalIcon(
        onPressed: () => bloc.add(FriendsEvent.requestSent(user.id)),
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
        label: Text(l10n.socialAddFriend),
      ),
      FriendshipRelation.requestSent when friendshipId != null => TextButton(
        onPressed: () => bloc.add(
          FriendsEvent.removed(
            friendshipId: friendshipId,
            message: SocialMessage.requestCancelled,
          ),
        ),
        child: Text(l10n.socialCancelRequest),
      ),
      FriendshipRelation.requestReceived when friendshipId != null =>
        FilledButton.tonal(
          onPressed: () => bloc.add(FriendsEvent.requestAccepted(friendshipId)),
          child: Text(l10n.socialAccept),
        ),
      FriendshipRelation.blocked when friendshipId != null => TextButton(
        onPressed: () => bloc.add(
          FriendsEvent.removed(
            friendshipId: friendshipId,
            message: SocialMessage.userUnblocked,
          ),
        ),
        child: Text(l10n.socialUnblock),
      ),
      FriendshipRelation.friends => Chip(
        avatar: const Icon(Icons.check_rounded, size: 16),
        label: Text(l10n.socialRelationFriends),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return UserTile(
      name: user.fullName,
      avatarUrl: user.avatarUrl,
      level: user.level,
      trailing: _action(context),
      onTap: () => _openProfileAndRefresh(context, user.id),
    );
  }
}

/// Abre el perfil público y, al volver, refresca las pestañas por si cambió
/// la relación desde allí.
Future<void> _openProfileAndRefresh(BuildContext context, String userId) async {
  final bloc = context.read<FriendsBloc>();
  await context.push<void>(SocialPaths.user(userId));
  for (final kind in FriendshipListKind.values) {
    bloc.add(FriendsEvent.sectionRefreshed(kind));
  }
}
