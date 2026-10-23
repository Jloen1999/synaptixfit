import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/feed_period.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/social/post.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../social_routes.dart';
import '../../widgets/post_card.dart';
import '../../widgets/post_editor_sheet.dart';
import '../../widgets/social_dialogs.dart';
import '../../widgets/social_feedback.dart';
import '../../widgets/social_layout.dart';
import '../bloc/feed_bloc.dart';

/// Muro social (`/social`).
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FeedBloc>()
        ..add(const FeedEvent.started())
        ..add(const FeedEvent.pollingStarted()),
      child: const _FeedView(),
    );
  }
}

class _FeedView extends StatefulWidget {
  const _FeedView();

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> with WidgetsBindingObserver {
  final _scroll = ScrollController();

  /// Rutas abiertas encima del muro (el sondeo se pausa mientras tanto).
  int _covered = 0;

  FeedBloc get _bloc => context.read<FeedBloc>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _covered == 0) {
      _bloc
        ..add(const FeedEvent.pollTicked())
        ..add(const FeedEvent.pollingStarted());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _bloc.add(const FeedEvent.pollingStopped());
    }
  }

  /// Navega pausando el sondeo hasta volver.
  Future<void> _push(String location) async {
    _covered++;
    _bloc.add(const FeedEvent.pollingStopped());
    await context.push<void>(location);
    if (!mounted) return;
    _covered--;
    if (_covered == 0) {
      _bloc
        ..add(const FeedEvent.pollTicked())
        ..add(const FeedEvent.pollingStarted());
    }
  }

  Future<void> _openPost(Post post) async {
    await _push(SocialPaths.post(post.id));
    if (mounted) _bloc.add(FeedEvent.postRefreshRequested(post.id));
  }

  /// Envía la acción al bloc y espera a que termine para devolver su error.
  Future<AppError?> _awaitSubmit(FeedEvent event) async {
    _bloc.add(event);
    final done = await _bloc.stream
        .skipWhile((s) => !s.submitting)
        .firstWhere((s) => !s.submitting);
    final feedback = done.feedback;
    return feedback is SocialFeedbackError ? feedback.error : null;
  }

  Future<void> _create() => showPostEditorSheet(
    context,
    onSubmit: (draft) => _awaitSubmit(
      FeedEvent.postSubmitted(
        type: draft.type,
        description: draft.description,
        imageUrl: draft.imageUrl,
      ),
    ),
  );

  Future<void> _edit(Post post) => showPostEditorSheet(
    context,
    initial: post,
    onSubmit: (draft) => _awaitSubmit(
      FeedEvent.postEdited(
        postId: post.id,
        description: draft.description,
        imageUrl: draft.imageUrl,
      ),
    ),
  );

  Future<void> _delete(Post post) async {
    final l10n = context.localizations;
    final ok = await confirmSocialAction(
      context,
      title: l10n.socialPostDeleteTitle,
      message: l10n.socialPostDeleteMessage,
      confirmLabel: l10n.commonDelete,
    );
    if (ok && mounted) _bloc.add(FeedEvent.postDeleted(post.id));
  }

  Future<void> _report(Post post) async {
    final l10n = context.localizations;
    final ok = await confirmSocialAction(
      context,
      title: l10n.socialReportPostTitle,
      message: l10n.socialReportMessage,
      confirmLabel: l10n.socialReport,
      destructive: false,
    );
    if (ok && mounted) _bloc.add(FeedEvent.postReported(post.id));
  }

  void _showNewPosts() {
    _bloc.add(const FeedEvent.newPostsShown());
    if (!_scroll.hasClients) return;
    if (context.reduceMotion) {
      _scroll.jumpTo(0);
    } else {
      unawaited(
        _scroll.animateTo(
          0,
          duration: TokensDuration.normal,
          curve: Curves.easeOut,
        ),
      );
    }
  }

  Future<void> _refresh() async {
    _bloc.add(const FeedEvent.refreshed());
    await _bloc.stream
        .skipWhile((s) => !s.refreshing)
        .firstWhere((s) => !s.refreshing);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocListener<FeedBloc, FeedState>(
      listenWhen: (_, current) => current.feedback != null,
      listener: (context, state) =>
          showSocialFeedback(context, state.feedback!),
      child: Scaffold(
        appBar: AppPageBar.reading(
          title: Text(l10n.socialFeedTitle),
          actions: [
            IconButton(
              tooltip: l10n.socialFriendsTitle,
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () => _push(SocialPaths.friends),
            ),
            BlocSelector<FeedBloc, FeedState, int>(
              selector: (state) => state.unreadNotifications,
              builder: (context, unread) => IconButton(
                tooltip: unread > 0
                    ? l10n.socialNotificationsUnreadTooltip(unread)
                    : l10n.socialNotificationsTitle,
                onPressed: () => _push(SocialPaths.notifications),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(
                    unread > 99 ? l10n.socialBadgeOverflow : '$unread',
                  ),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _create,
          icon: const Icon(Icons.edit_rounded),
          label: Text(l10n.socialPublish),
        ),
        body: Column(
          children: [
            const _PeriodFilter(),
            Expanded(
              child: BlocBuilder<FeedBloc, FeedState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.posts != current.posts ||
                    previous.newPosts.length != current.newPosts.length ||
                    previous.loadingMore != current.loadingMore ||
                    previous.hasMore != current.hasMore,
                builder: (context, state) => switch (state.status) {
                  SocialLoadStatus.loading => const SocialListSkeleton(),
                  SocialLoadStatus.failure => AppErrorView(
                    error: state.error!,
                    onRetry: () => _bloc.add(const FeedEvent.started()),
                  ),
                  SocialLoadStatus.loaded => Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: _refresh,
                        child: state.posts.isEmpty
                            ? _EmptyFeed(onCreate: _create)
                            : _postList(state),
                      ),
                      if (state.newPosts.isNotEmpty)
                        Positioned(
                          top: TokensSpacing.s,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: FilledButton.icon(
                              onPressed: _showNewPosts,
                              icon: const Icon(Icons.arrow_upward_rounded),
                              label: Text(
                                l10n.socialNewPosts(state.newPosts.length),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postList(FeedState state) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) => onScrollNearEnd(
        n,
        () => _bloc.add(const FeedEvent.nextPageRequested()),
      ),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.m,
          TokensSpacing.m,
          TokensSpacing.m,
          TokensSpacing.xxl * 2,
        ),
        itemCount: state.posts.length + (state.loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: TokensSpacing.m),
        itemBuilder: (context, index) {
          if (index >= state.posts.length) return const LoadMoreIndicator();
          final post = state.posts[index];
          return SocialContentWidth(
            child: PostCard(
              key: ValueKey(post.id),
              post: post,
              expandableComments: true,
              onLike: () => _bloc.add(FeedEvent.likeToggled(post.id)),
              onOpen: () => _openPost(post),
              onAuthorTap: (userId) => _push(SocialPaths.user(userId)),
              onEdit: () => _edit(post),
              onDelete: () => _delete(post),
              onReport: () => _report(post),
              onLinkTap: _push,
              onCommentsCountChanged: (count) => _bloc.add(
                FeedEvent.commentsCountChanged(postId: post.id, count: count),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final labels = {
      FeedPeriod.all: l10n.socialPeriodAll,
      FeedPeriod.today: l10n.socialPeriodToday,
      FeedPeriod.week: l10n.socialPeriodWeek,
      FeedPeriod.month: l10n.socialPeriodMonth,
    };
    return BlocSelector<FeedBloc, FeedState, FeedPeriod>(
      selector: (state) => state.period,
      builder: (context, period) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.m,
          TokensSpacing.s,
          TokensSpacing.m,
          0,
        ),
        child: Row(
          children: [
            for (final entry in labels.entries) ...[
              ChoiceChip(
                label: Text(entry.value),
                selected: period == entry.key,
                onSelected: (_) => context.read<FeedBloc>().add(
                  FeedEvent.periodChanged(entry.key),
                ),
              ),
              const SizedBox(width: TokensSpacing.s),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: AppEmptyState(
            icon: Icons.forum_outlined,
            title: l10n.socialFeedEmptyTitle,
            message: l10n.socialFeedEmptyMessage,
            action: AppPrimaryButton(
              label: l10n.socialPublish,
              icon: Icons.edit_rounded,
              onPressed: onCreate,
            ),
          ),
        ),
      ),
    );
  }
}
