import 'package:flutter/material.dart';

import '../../../../../domain/models/social/public_profile.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../progress/widgets/badge_tile.dart';
import '../../../progress/widgets/progress_labels.dart';
import '../../widgets/social_layout.dart';

/// Insignias que otra persona enseña en su perfil. Se ven las primeras y el
/// resto en una hoja; cada una se toca para saber qué es y cuándo la ganó.
class PublicBadgesSection extends StatelessWidget {
  const PublicBadgesSection({super.key, required this.profile});

  final PublicProfile profile;

  /// Una fila y media en un móvil: suficiente para hacerse una idea sin
  /// empujar las publicaciones fuera de la pantalla.
  static const visible = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final badges = profile.badges;
    if (badges.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: TokensSpacing.l),
        SocialContentWidth(
          child: AppSectionHeader(
            title: l10n.socialProfileBadges(badges.length),
            actionLabel: badges.length > visible
                ? l10n.socialProfileBadgesAll(badges.length)
                : null,
            onAction: () => _showAll(context, badges),
          ),
        ),
        SocialContentWidth(
          child: Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.s,
            children: [
              for (final badge in badges.take(visible))
                PublicBadgeTile(badge: badge),
            ],
          ),
        ),
      ],
    );
  }

  void _showAll(BuildContext context, List<PublicBadge> badges) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(TokensSpacing.m),
            children: [
              Text(
                context.localizations.socialProfileBadges(badges.length),
                style: context.textStyles.titleLarge,
              ),
              const SizedBox(height: TokensSpacing.m),
              Wrap(
                spacing: TokensSpacing.s,
                runSpacing: TokensSpacing.s,
                children: [
                  for (final badge in badges) PublicBadgeTile(badge: badge),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Emblema con su nombre; al tocarlo explica la insignia.
class PublicBadgeTile extends StatelessWidget {
  const PublicBadgeTile({super.key, required this.badge});

  final PublicBadge badge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return SizedBox(
      width: TokensSize.medallion,
      child: Semantics(
        button: true,
        label: l10n.socialProfileBadgeSemantics(
          badge.name,
          l10n.badgeRarity(badge.rarity),
        ),
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          onTap: () => _showDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(TokensSpacing.xs),
            child: Column(
              children: [
                BadgeEmblem.raw(
                  icon: badge.icon,
                  rarity: badge.rarity,
                  size: TokensSize.thumbnailS,
                ),
                const SizedBox(height: TokensSpacing.xs),
                Text(
                  badge.name,
                  style: context.textStyles.labelMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final l10n = context.localizations;
    final earnedAt = badge.earnedAt;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: TokensSpacing.l,
            right: TokensSpacing.l,
            bottom: TokensSpacing.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgeEmblem.raw(
                icon: badge.icon,
                rarity: badge.rarity,
                size: TokensSize.medallion,
              ),
              const SizedBox(height: TokensSpacing.m),
              Text(
                badge.name,
                style: context.textStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TokensSpacing.xs),
              Text(
                l10n.badgeRarity(badge.rarity),
                style: context.textStyles.labelLarge?.copyWith(
                  color: context.rarityColor(badge.rarity),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              Text(
                badge.description,
                style: context.textStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (earnedAt != null) ...[
                const SizedBox(height: TokensSpacing.s),
                Text(
                  l10n.socialProfileBadgeEarnedOn(
                    ProgressFormat.date(earnedAt),
                  ),
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
