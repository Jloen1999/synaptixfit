import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/models/social/post_comment.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../comments/bloc/comments_bloc.dart';
import 'social_dialogs.dart';
import 'social_feedback.dart';
import 'social_format.dart';

enum _CommentAction { edit, delete, report }

/// Un comentario con su autor; el autor puede editarlo o borrarlo y el resto
/// reportarlo.
class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment, this.onAuthorTap});

  final PostComment comment;
  final VoidCallback? onAuthorTap;

  Future<void> _onAction(BuildContext context, _CommentAction action) async {
    final l10n = context.localizations;
    final bloc = context.read<CommentsBloc>();
    switch (action) {
      case _CommentAction.edit:
        final text = await editCommentDialog(context, comment.text);
        if (text != null && text != comment.text) {
          bloc.add(CommentsEvent.edited(commentId: comment.id, text: text));
        }
      case _CommentAction.delete:
        final ok = await confirmSocialAction(
          context,
          title: l10n.socialCommentDeleteTitle,
          message: l10n.socialCommentDeleteMessage,
          confirmLabel: l10n.commonDelete,
        );
        if (ok) bloc.add(CommentsEvent.deleted(comment.id));
      case _CommentAction.report:
        final ok = await confirmSocialAction(
          context,
          title: l10n.socialReportCommentTitle,
          message: l10n.socialReportMessage,
          confirmLabel: l10n.socialReport,
          destructive: false,
        );
        if (ok) bloc.add(CommentsEvent.reported(comment.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final muted = context.textStyles.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: onAuthorTap != null,
            label: comment.author.fullName,
            child: AppFocusOutline(
              borderRadius: BorderRadius.circular(TokensRadius.pill),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAuthorTap,
                // El relleno lleva el área táctil a 48 dp sin agrandar el avatar.
                child: Padding(
                  padding: const EdgeInsets.all(TokensSpacing.s),
                  child: AppAvatar(
                    name: comment.author.fullName,
                    imageUrl: comment.author.avatarUrl,
                    radius: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: TokensSpacing.s),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TokensSpacing.m,
                vertical: TokensSpacing.s,
              ),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(TokensRadius.m),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.author.fullName,
                    style: context.textStyles.labelLarge,
                  ),
                  const SizedBox(height: TokensSpacing.xxs),
                  Text(comment.text, style: context.textStyles.bodyMedium),
                  const SizedBox(height: TokensSpacing.xxs),
                  Text(
                    comment.edited
                        ? l10n.socialTimeEdited(
                            socialTimeAgo(l10n, comment.createdAt),
                          )
                        : socialTimeAgo(l10n, comment.createdAt),
                    style: muted,
                  ),
                ],
              ),
            ),
          ),
          // Una o dos acciones: a la vista con su icono de siempre (lápiz,
          // papelera, reportar), sin menú de tres puntos.
          if (comment.mine) ...[
            IconButton(
              tooltip: l10n.socialEditCommentTooltip,
              icon: const Icon(AppIcons.edit),
              onPressed: () => _onAction(context, _CommentAction.edit),
            ),
            IconButton(
              tooltip: l10n.socialDeleteCommentTooltip,
              icon: const Icon(AppIcons.delete),
              onPressed: () => _onAction(context, _CommentAction.delete),
            ),
          ] else
            IconButton(
              tooltip: l10n.socialReport,
              icon: const Icon(AppIcons.report),
              onPressed: () => _onAction(context, _CommentAction.report),
            ),
        ],
      ),
    );
  }
}

/// Campo para escribir un comentario (1-500 caracteres) con botón de envío.
class CommentInput extends StatefulWidget {
  const CommentInput({super.key, this.autofocus = false});

  final bool autofocus;

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CommentsBloc>().add(CommentsEvent.submitted(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<CommentsBloc, CommentsState>(
      listenWhen: (previous, current) =>
          previous.sentCount != current.sentCount,
      listener: (_, _) {
        _controller.clear();
        _formKey.currentState?.reset();
      },
      buildWhen: (previous, current) => previous.sending != current.sending,
      builder: (context, state) => Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                autofocus: widget.autofocus,
                enabled: !state.sending,
                minLines: 1,
                maxLines: 4,
                maxLength: commentMaxLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  labelText: l10n.socialCommentHint,
                  isDense: true,
                ),
                validator: (value) => validateComment(context, value),
              ),
            ),
            const SizedBox(width: TokensSpacing.xs),
            SizedBox.square(
              dimension: 48,
              child: state.sending
                  ? const Padding(
                      padding: EdgeInsets.all(TokensSpacing.m),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      tooltip: l10n.socialCommentSend,
                      onPressed: _send,
                      icon: Icon(AppIcons.send, color: context.colors.primary),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de comentarios para la tarjeta del muro: últimos comentarios, «ver
/// anteriores/más» y campo de envío. Requiere un [CommentsBloc] arriba.
class CommentsSection extends StatelessWidget {
  const CommentsSection({super.key, this.onCountChanged, this.onAuthorTap});

  final ValueChanged<int>? onCountChanged;
  final ValueChanged<String>? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<CommentsBloc, CommentsState>(
      listenWhen: (previous, current) =>
          current.feedback != null ||
          (previous.totalCount != current.totalCount &&
              current.status == SocialLoadStatus.loaded),
      listener: (context, state) {
        final feedback = state.feedback;
        if (feedback != null) showSocialFeedback(context, feedback);
        onCountChanged?.call(state.totalCount);
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            switch (state.status) {
              SocialLoadStatus.loading => const AppSkeletonGroup(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: TokensSpacing.s),
                  child: AppSkeleton(height: 48),
                ),
              ),
              SocialLoadStatus.failure => AppErrorView(
                error: state.error!,
                onRetry: () => context.read<CommentsBloc>().add(
                  CommentsEvent.started(state.postId),
                ),
              ),
              SocialLoadStatus.loaded when state.comments.isEmpty => Padding(
                padding: const EdgeInsets.symmetric(vertical: TokensSpacing.s),
                child: Text(
                  l10n.socialCommentsEmpty,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              SocialLoadStatus.loaded => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final comment in state.comments)
                    CommentTile(
                      comment: comment,
                      onAuthorTap: onAuthorTap == null
                          ? null
                          : () => onAuthorTap!(comment.author.id),
                    ),
                  if (state.hasMore)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: state.loadingMore
                          ? const Padding(
                              padding: EdgeInsets.all(TokensSpacing.s),
                              child: SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: () => context.read<CommentsBloc>().add(
                                const CommentsEvent.nextPageRequested(),
                              ),
                              child: Text(l10n.socialCommentsLoadMore),
                            ),
                    ),
                ],
              ),
            },
            const SizedBox(height: TokensSpacing.s),
            const CommentInput(),
          ],
        );
      },
    );
  }
}
