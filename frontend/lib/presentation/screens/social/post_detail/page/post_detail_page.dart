import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/social/post.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../comments/bloc/comments_bloc.dart';
import '../../social_routes.dart';
import '../../widgets/comment_widgets.dart';
import '../../widgets/post_card.dart';
import '../../widgets/post_editor_sheet.dart';
import '../../widgets/social_dialogs.dart';
import '../../widgets/social_feedback.dart';
import '../../widgets/social_layout.dart';
import '../bloc/post_detail_bloc.dart';

/// Detalle de una publicación con sus comentarios (`/social/posts/:postId`).
/// Es el destino de los enlaces de las notificaciones sociales.
class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<PostDetailBloc>()..add(PostDetailEvent.started(postId)),
        ),
        BlocProvider(
          create: (_) =>
              getIt<CommentsBloc>()..add(CommentsEvent.started(postId)),
        ),
      ],
      child: const _PostDetailView(),
    );
  }
}

class _PostDetailView extends StatelessWidget {
  const _PostDetailView();

  Future<AppError?> _awaitEdit(PostDetailBloc bloc, PostDraft draft) async {
    bloc.add(
      PostDetailEvent.edited(
        description: draft.description,
        imageUrl: draft.imageUrl,
      ),
    );
    final done = await bloc.stream
        .skipWhile((s) => !s.submitting)
        .firstWhere((s) => !s.submitting);
    final feedback = done.feedback;
    return feedback is SocialFeedbackError ? feedback.error : null;
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<PostDetailBloc>();
    final ok = await confirmSocialAction(
      context,
      title: l10n.socialPostDeleteTitle,
      message: l10n.socialPostDeleteMessage,
      confirmLabel: l10n.commonDelete,
    );
    if (ok) bloc.add(const PostDetailEvent.deleted());
  }

  Future<void> _report(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<PostDetailBloc>();
    final ok = await confirmSocialAction(
      context,
      title: l10n.socialReportPostTitle,
      message: l10n.socialReportMessage,
      confirmLabel: l10n.socialReport,
      destructive: false,
    );
    if (ok) bloc.add(const PostDetailEvent.reported());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return MultiBlocListener(
      listeners: [
        BlocListener<PostDetailBloc, PostDetailState>(
          listenWhen: (_, current) => current.feedback != null,
          listener: (context, state) {
            showSocialFeedback(context, state.feedback!);
            if (state.deleted) context.pop();
          },
        ),
        BlocListener<CommentsBloc, CommentsState>(
          listenWhen: (previous, current) =>
              current.feedback != null ||
              previous.totalCount != current.totalCount,
          listener: (context, state) {
            if (state.feedback != null) {
              showSocialFeedback(context, state.feedback!);
            }
            if (state.status == SocialLoadStatus.loaded) {
              context.read<PostDetailBloc>().add(
                PostDetailEvent.commentsCountChanged(state.totalCount),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppPageBar.reading(title: Text(l10n.socialPostTitle)),
        body: BlocBuilder<PostDetailBloc, PostDetailState>(
          builder: (context, state) => switch (state.status) {
            SocialLoadStatus.loading => const SocialListSkeleton(
              itemHeight: 220,
              count: 2,
            ),
            SocialLoadStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => context.read<PostDetailBloc>().add(
                PostDetailEvent.started(state.postId),
              ),
            ),
            SocialLoadStatus.loaded => _content(context, state.post!),
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Post post) {
    final l10n = context.localizations;
    final detail = context.read<PostDetailBloc>();
    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) => onScrollNearEnd(
              n,
              () => context.read<CommentsBloc>().add(
                const CommentsEvent.nextPageRequested(),
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                detail.add(PostDetailEvent.started(post.id));
                context.read<CommentsBloc>().add(
                  CommentsEvent.started(post.id),
                );
              },
              child: ListView(
                padding: const EdgeInsets.all(TokensSpacing.m),
                children: [
                  SocialContentWidth(
                    child: PostCard(
                      post: post,
                      onLike: () =>
                          detail.add(const PostDetailEvent.likeToggled()),
                      onAuthorTap: (id) =>
                          context.push<void>(SocialPaths.user(id)),
                      onEdit: () => showPostEditorSheet(
                        context,
                        initial: post,
                        onSubmit: (draft) => _awaitEdit(detail, draft),
                      ),
                      onDelete: () => _delete(context),
                      onReport: () => _report(context),
                      onLinkTap: (route) => context.push<void>(route),
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.l),
                  SocialContentWidth(
                    child: AppSectionHeader(
                      title: l10n.socialCommentsCount(post.commentsCount),
                    ),
                  ),
                  const SocialContentWidth(child: _CommentsList()),
                ],
              ),
            ),
          ),
        ),
        Material(
          color: context.colors.surface,
          child: const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                TokensSpacing.m,
                TokensSpacing.s,
                TokensSpacing.s,
                TokensSpacing.s,
              ),
              child: SocialContentWidth(child: CommentInput()),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<CommentsBloc, CommentsState>(
      builder: (context, state) => switch (state.status) {
        SocialLoadStatus.loading => const AppSkeletonGroup(
          child: Column(
            children: [
              AppSkeleton(height: 56),
              SizedBox(height: TokensSpacing.s),
              AppSkeleton(height: 56),
            ],
          ),
        ),
        SocialLoadStatus.failure => AppErrorView(
          error: state.error!,
          onRetry: () => context.read<CommentsBloc>().add(
            CommentsEvent.started(state.postId),
          ),
        ),
        SocialLoadStatus.loaded when state.comments.isEmpty => AppEmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          title: l10n.socialCommentsEmpty,
          message: l10n.socialCommentsEmptyMessage,
        ),
        SocialLoadStatus.loaded => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final comment in state.comments)
              CommentTile(
                comment: comment,
                onAuthorTap: () =>
                    context.push<void>(SocialPaths.user(comment.author.id)),
              ),
            if (state.loadingMore) const LoadMoreIndicator(),
          ],
        ),
      },
    );
  }
}
