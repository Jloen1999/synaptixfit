import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/app_di.dart';
import '../../../../domain/models/social/post.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../comments/bloc/comments_bloc.dart';
import 'comment_widgets.dart';
import 'social_format.dart';

enum _PostAction { edit, delete, report }

/// Tarjeta de publicación: autor, tipo, texto, imagen, enlace, «me gusta»
/// animado y comentarios (expandibles dentro de la tarjeta si se pide).
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    this.onOpen,
    this.onAuthorTap,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onLinkTap,
    this.expandableComments = false,
    this.onCommentsCountChanged,
  });

  final Post post;
  final VoidCallback onLike;

  /// Abre el detalle; si es nulo, el botón de comentarios no navega.
  final VoidCallback? onOpen;
  final ValueChanged<String>? onAuthorTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final ValueChanged<String>? onLinkTap;
  final bool expandableComments;
  final ValueChanged<int>? onCommentsCountChanged;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _commentsOpen = false;

  Post get post => widget.post;

  void _onCommentsPressed() {
    if (widget.expandableComments) {
      setState(() => _commentsOpen = !_commentsOpen);
    } else {
      widget.onOpen?.call();
    }
  }

  List<PopupMenuEntry<_PostAction>> _menu(BuildContext context) {
    final l10n = context.localizations;
    return post.mine
        ? [
            if (widget.onEdit != null)
              PopupMenuItem(
                value: _PostAction.edit,
                child: Text(l10n.commonEdit),
              ),
            if (widget.onDelete != null)
              PopupMenuItem(
                value: _PostAction.delete,
                child: Text(l10n.commonDelete),
              ),
          ]
        : [
            if (widget.onReport != null)
              PopupMenuItem(
                value: _PostAction.report,
                child: Text(l10n.socialReport),
              ),
          ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final typeColor = post.type.color(context);
    final menu = _menu(context);
    final link = post.link;
    final linkRoute = link?.route;
    return AppCard(
      onTap: widget.onOpen,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.m,
              TokensSpacing.m,
              TokensSpacing.xs,
              0,
            ),
            child: Row(
              children: [
                Semantics(
                  button: widget.onAuthorTap != null,
                  label: l10n.socialOpenProfileOf(post.author.fullName),
                  child: AppFocusOutline(
                    borderRadius: BorderRadius.circular(TokensRadius.pill),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onAuthorTap == null
                          ? null
                          : () => widget.onAuthorTap!(post.author.id),
                      child: AppAvatar(
                        name: post.author.fullName,
                        imageUrl: post.author.avatarUrl,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.fullName,
                        style: context.textStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        post.edited
                            ? l10n.socialTimeEdited(
                                socialTimeAgo(l10n, post.createdAt),
                              )
                            : socialTimeAgo(l10n, post.createdAt),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (menu.isNotEmpty)
                  PopupMenuButton<_PostAction>(
                    tooltip: l10n.socialMoreActions,
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) => switch (action) {
                      _PostAction.edit => widget.onEdit?.call(),
                      _PostAction.delete => widget.onDelete?.call(),
                      _PostAction.report => widget.onReport?.call(),
                    },
                    itemBuilder: (_) => menu,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.m,
              TokensSpacing.s,
              TokensSpacing.m,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPill(
                  label: post.type.label(l10n),
                  icon: post.type.icon,
                  color: typeColor,
                ),
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: TokensSpacing.s),
                  Text(post.description, style: context.textStyles.bodyLarge),
                ],
                if (link != null) ...[
                  const SizedBox(height: TokensSpacing.s),
                  ActionChip(
                    avatar: Icon(link.icon, size: 18, color: typeColor),
                    label: Text(link.name),
                    onPressed: linkRoute == null || widget.onLinkTap == null
                        ? null
                        : () => widget.onLinkTap!(linkRoute),
                  ),
                ],
              ],
            ),
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: TokensSpacing.s),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TokensRadius.m),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const AppSkeleton(height: 200),
                    errorWidget: (_, _, _) => Container(
                      height: 120,
                      color: context.colors.surfaceContainer,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: context.colors.onSurfaceVariant,
                        semanticLabel: l10n.socialPostImageLoadError,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensSpacing.xs,
              vertical: TokensSpacing.xs,
            ),
            child: Row(
              children: [
                LikeButton(
                  liked: post.likedByMe,
                  count: post.likesCount,
                  onPressed: widget.onLike,
                ),
                TextButton.icon(
                  onPressed: widget.expandableComments || widget.onOpen != null
                      ? _onCommentsPressed
                      : null,
                  icon: Icon(
                    _commentsOpen
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                  ),
                  label: Text(l10n.socialCommentsCount(post.commentsCount)),
                ),
              ],
            ),
          ),
          if (_commentsOpen)
            BlocProvider(
              create: (_) =>
                  getIt<CommentsBloc>()..add(CommentsEvent.started(post.id)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  0,
                  TokensSpacing.xs,
                  TokensSpacing.m,
                ),
                child: CommentsSection(
                  onCountChanged: widget.onCommentsCountChanged,
                  onAuthorTap: widget.onAuthorTap,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Botón de «me gusta» con contador y animación de rebote al cambiar.
class LikeButton extends StatefulWidget {
  const LikeButton({
    super.key,
    required this.liked,
    required this.count,
    required this.onPressed,
  });

  final bool liked;
  final int count;
  final VoidCallback onPressed;

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: TokensDuration.slow,
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.35), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1), weight: 60),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(covariant LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.liked && !oldWidget.liked && !_reduceMotion) {
      _controller.forward(from: 0);
    }
  }

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = widget.liked
        ? context.colors.error
        : context.colors.onSurfaceVariant;
    return Semantics(
      toggled: widget.liked,
      child: TextButton.icon(
        onPressed: widget.onPressed,
        style: TextButton.styleFrom(foregroundColor: color),
        icon: ScaleTransition(
          scale: _scale,
          child: Icon(
            widget.liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            semanticLabel: widget.liked ? l10n.socialUnlike : l10n.socialLike,
          ),
        ),
        label: Text(l10n.socialLikesCount(widget.count)),
      ),
    );
  }
}
