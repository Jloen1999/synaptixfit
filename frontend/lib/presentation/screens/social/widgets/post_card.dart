import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/app_di.dart';
import '../../../../domain/models/social/post.dart';
import '../../../../domain/models/social/post_link.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../comments/bloc/comments_bloc.dart';
import 'comment_widgets.dart';
import 'social_format.dart';

/// Tarjeta de publicación del muro, pensada para leerse de un vistazo: quién
/// (avatar con el icono del tipo y nombre, que llevan a su perfil), qué pasó
/// (tipo en su acento y cuándo), el texto y la imagen (abren el detalle), lo
/// que enlaza (un reto, una insignia o una rutina, en un panel de su acento) y
/// las interacciones. La tarjeta no es pulsable entera: cada zona es su propio
/// botón, sin toques anidados.
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

  /// Abre el detalle; si es nulo, el texto no es pulsable y el botón de
  /// comentarios no navega.
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final link = post.link;
    final linkRoute = link?.route;
    final onAuthorTap = widget.onAuthorTap;
    final body = _PostBody(post: post);
    final hasBody = post.description.isNotEmpty || post.imageUrl != null;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.s,
              TokensSpacing.s,
              TokensSpacing.xs,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PostAuthor(
                    post: post,
                    onTap: onAuthorTap == null
                        ? null
                        : () => onAuthorTap(post.author.id),
                  ),
                ),
                // Como mucho dos acciones: a la vista, sin menú de tres puntos.
                if (post.mine) ...[
                  if (widget.onEdit != null)
                    IconButton(
                      tooltip: l10n.commonEdit,
                      icon: const Icon(AppIcons.edit),
                      onPressed: widget.onEdit,
                    ),
                  if (widget.onDelete != null)
                    IconButton(
                      tooltip: l10n.commonDelete,
                      icon: const Icon(AppIcons.delete),
                      onPressed: widget.onDelete,
                    ),
                ] else if (widget.onReport != null)
                  IconButton(
                    tooltip: l10n.socialReport,
                    icon: const Icon(AppIcons.report),
                    onPressed: widget.onReport,
                  ),
              ],
            ),
          ),
          if (hasBody)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.s),
              // El texto y la imagen abren el detalle (en el detalle, nada).
              child: widget.onOpen == null
                  ? Padding(
                      padding: const EdgeInsets.all(TokensSpacing.s),
                      child: body,
                    )
                  : AppCardTapArea(
                      onTap: widget.onOpen,
                      semanticHint: l10n.socialOpenPostHint,
                      padding: const EdgeInsets.all(TokensSpacing.s),
                      child: body,
                    ),
            ),
          if (link != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                TokensSpacing.m,
                hasBody ? 0 : TokensSpacing.s,
                TokensSpacing.m,
                0,
              ),
              child: _LinkedContent(
                link: link,
                kindLabel: switch (link.kind) {
                  PostLinkKind.routine => l10n.socialPostTypeRoutine,
                  PostLinkKind.challenge => l10n.socialPostTypeChallenge,
                  PostLinkKind.badge => l10n.socialLinkBadge,
                },
                color: post.type.color(context),
                onTap: linkRoute == null || widget.onLinkTap == null
                    ? null
                    : () => widget.onLinkTap!(linkRoute),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensSpacing.xs,
              vertical: TokensSpacing.xs,
            ),
            child: Wrap(
              spacing: TokensSpacing.xs,
              children: [
                LikeButton(
                  liked: post.likedByMe,
                  count: post.likesCount,
                  onPressed: widget.onLike,
                ),
                Semantics(
                  expanded: widget.expandableComments ? _commentsOpen : null,
                  child: TextButton.icon(
                    onPressed:
                        widget.expandableComments || widget.onOpen != null
                        ? _onCommentsPressed
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.onSurfaceVariant,
                    ),
                    icon: Icon(
                      _commentsOpen
                          ? Icons.chat_bubble_rounded
                          : Icons.chat_bubble_outline_rounded,
                    ),
                    label: Text(l10n.socialCommentsCount(post.commentsCount)),
                  ),
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

/// Quién y qué: avatar con el icono del tipo en su acento, nombre y debajo
/// «Reto completado · hace 3 h». Si [onTap] no es nulo, todo es un botón que
/// abre el perfil del autor.
class _PostAuthor extends StatelessWidget {
  const _PostAuthor({required this.post, required this.onTap});

  final Post post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = post.type.color(context);
    final time = socialTimeAgo(l10n, post.createdAt);
    final when = post.edited ? l10n.socialTimeEdited(time) : time;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: TokensLayout.minTouchTarget),
      child: Row(
        children: [
          SocialTypedAvatar(
            name: post.author.fullName,
            imageUrl: post.author.avatarUrl,
            icon: post.type.icon,
            color: color,
          ),
          const SizedBox(width: TokensSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  post.author.fullName,
                  style: context.textStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: post.type.label(l10n),
                        style: context.textStyles.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ' · $when'),
                    ],
                  ),
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.all(TokensSpacing.s),
        child: content,
      );
    }
    return AppCardTapArea(
      onTap: onTap,
      padding: const EdgeInsets.all(TokensSpacing.s),
      semanticLabel: [
        l10n.socialOpenProfileOf(post.author.fullName),
        post.type.label(l10n),
        when,
      ].join(', '),
      child: content,
    );
  }
}

/// Texto e imagen de la publicación.
class _PostBody extends StatelessWidget {
  const _PostBody({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final imageUrl = post.imageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (post.description.isNotEmpty)
          Text(post.description, style: context.textStyles.bodyLarge),
        if (post.description.isNotEmpty && imageUrl != null)
          const SizedBox(height: TokensSpacing.s),
        if (imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(TokensRadius.m),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: TokensSize.postImageMaxHeight,
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, _) => const AppSkeleton(
                  height: TokensSize.postImageMaxHeight / 2,
                ),
                errorWidget: (_, _, _) => Container(
                  height: TokensSize.emptyBadge,
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
      ],
    );
  }
}

/// Lo que enlaza la publicación (el reto completado, la insignia, la rutina)
/// en un panel del acento del tipo: un icono grande y el nombre. Es lo más
/// vistoso de una publicación sin foto. Si tiene ruta, lleva a su pantalla.
class _LinkedContent extends StatelessWidget {
  const _LinkedContent({
    required this.link,
    required this.kindLabel,
    required this.color,
    required this.onTap,
  });

  final PostLink link;

  /// Qué es lo enlazado («Reto», «Insignia»): el lector lo oye antes del nombre.
  final String kindLabel;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = Color.alphaBlend(
      color.withValues(alpha: AppPill.tintAlpha),
      context.colors.surface,
    );
    const radius = BorderRadius.all(Radius.circular(TokensRadius.m));
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: TokensLayout.minTouchTarget),
      child: Row(
        children: [
          Container(
            width: TokensSize.thumbnailS,
            height: TokensSize.thumbnailS,
            decoration: BoxDecoration(
              color: context.colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(link.icon, color: color, size: TokensSize.iconM),
          ),
          const SizedBox(width: TokensSpacing.sm),
          Expanded(
            child: Text(
              link.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.titleSmall,
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant,
            ),
        ],
      ),
    );
    return Material(
      color: tint,
      borderRadius: radius,
      child: onTap == null
          ? Padding(
              padding: const EdgeInsets.all(TokensSpacing.s),
              child: content,
            )
          : AppCardTapArea(
              onTap: onTap,
              semanticLabel: '$kindLabel: ${link.name}',
              borderRadius: radius,
              padding: const EdgeInsets.all(TokensSpacing.s),
              child: content,
            ),
    );
  }
}

/// Avatar con una insignia redonda abajo a la derecha: el icono del tipo de
/// publicación sobre su acento. Da color al muro sin necesidad de foto.
class SocialTypedAvatar extends StatelessWidget {
  const SocialTypedAvatar({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    this.imageUrl,
  });

  final String name;
  final String? imageUrl;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const radius = TokensSize.thumbnailS / 2;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: TokensSize.thumbnailS + TokensSpacing.xs,
        child: Stack(
          children: [
            AppAvatar(name: name, imageUrl: imageUrl, radius: radius),
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(TokensSpacing.xxs),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  // Aro de la superficie: separa la insignia de la foto.
                  border: Border.all(
                    color: context.colors.surface,
                    width: TokensSpacing.xxs,
                  ),
                ),
                child: Icon(
                  icon,
                  size: TokensSize.iconXs,
                  color: context.colors.surface,
                ),
              ),
            ),
          ],
        ),
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
