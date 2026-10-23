import 'package:flutter/material.dart';

import '../../../../domain/enums/community_post_kind.dart';
import '../../../../domain/models/progress/community_post_preview.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'chart_card.dart';
import 'progress_labels.dart';

/// Puerta al muro social: solo la última publicación, para no repetir aquí
/// el muro entero (está a un toque con «Ver todo»).
class CommunityPreviewCard extends StatelessWidget {
  const CommunityPreviewCard({
    super.key,
    required this.posts,
    required this.onOpenWall,
    required this.onOpenPost,
  });

  /// Nulo si no se pudo cargar.
  final List<CommunityPostPreview>? posts;
  final VoidCallback onOpenWall;
  final ValueChanged<CommunityPostPreview> onOpenPost;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final items = posts;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.progressCommunityTitle,
                  style: context.textStyles.titleMedium,
                ),
              ),
              TextButton(onPressed: onOpenWall, child: Text(l10n.commonSeeAll)),
            ],
          ),
          if (items == null)
            InlineNotice(
              icon: Icons.cloud_off_rounded,
              message: l10n.progressSectionUnavailable,
            )
          else if (items.isEmpty)
            InlineNotice(
              icon: Icons.forum_outlined,
              message: l10n.progressCommunityEmpty,
            )
          else
            _PostTile(post: items.first, onTap: () => onOpenPost(items.first)),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post, required this.onTap});

  final CommunityPostPreview post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final muted = context.textStyles.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return AppFocusOutline(
      borderRadius: BorderRadius.circular(TokensRadius.m),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: TokensLayout.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(
                  name: post.authorName,
                  imageUrl: post.authorAvatarUrl,
                  radius: 18,
                ),
                const SizedBox(width: TokensSpacing.s + TokensSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.authorName,
                              style: context.textStyles.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            ProgressFormat.relative(
                              post.createdAt,
                              DateTime.now(),
                            ),
                            style: muted,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            _kindIcon(post.kind),
                            size: 14,
                            color: context.colors.primary,
                          ),
                          const SizedBox(width: TokensSpacing.xxs),
                          Text(l10n.postKind(post.kind), style: muted),
                        ],
                      ),
                      if (post.description.isNotEmpty) ...[
                        const SizedBox(height: TokensSpacing.xxs),
                        Text(
                          post.description,
                          style: context.textStyles.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: TokensSpacing.xxs),
                      Text(
                        '${l10n.progressCommunityLikes(post.likesCount)} · '
                        '${l10n.progressCommunityComments(post.commentsCount)}',
                        style: muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _kindIcon(CommunityPostKind kind) => switch (kind) {
    CommunityPostKind.sessionCompleted => Icons.fitness_center_rounded,
    CommunityPostKind.challengeCompleted => Icons.flag_rounded,
    CommunityPostKind.milestoneReached => Icons.local_fire_department_rounded,
    CommunityPostKind.badgeUnlocked => Icons.military_tech_rounded,
    CommunityPostKind.routine => Icons.list_alt_rounded,
    CommunityPostKind.challenge => Icons.outlined_flag_rounded,
    CommunityPostKind.other => Icons.chat_bubble_outline_rounded,
  };
}
