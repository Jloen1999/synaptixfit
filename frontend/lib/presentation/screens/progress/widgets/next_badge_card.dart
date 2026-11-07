import 'package:flutter/material.dart' hide Badge;

import '../../../../domain/models/progress/badge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'badge_tile.dart';
import 'progress_labels.dart';

/// «Próxima insignia» en Progreso: la bloqueada más avanzada, qué pide y
/// cuánto falta (progreso del servidor). Toda la tarjeta abre las insignias.
class NextBadgeCard extends StatelessWidget {
  const NextBadgeCard({super.key, required this.badge, required this.onOpen});

  final Badge badge;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final target = badge.criterionValue;
    final current = badge.currentValue.clamp(0, target);
    final remaining = target - current;
    final criterion = l10n.badgeCriterion(badge);
    final amount = l10n.progressNextBadgeAmount(current, target, remaining);
    return AppCard(
      onTap: onOpen,
      child: Semantics(
        hint: l10n.progressNextBadgeHint,
        label:
            '${l10n.progressNextBadgeTitle}: ${badge.name}. '
            '$criterion. $amount',
        excludeSemantics: true,
        child: Row(
          children: [
            BadgeEmblem(badge: badge, size: TokensSize.thumbnailS),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.progressNextBadgeTitle,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(badge.name, style: context.textStyles.titleMedium),
                  Text(criterion, style: context.textStyles.bodySmall),
                  const SizedBox(height: TokensSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(TokensRadius.pill),
                    child: LinearProgressIndicator(
                      value: badge.progress,
                      color: context.palette.accent,
                      backgroundColor: context.colors.outlineVariant,
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.xxs),
                  Text(
                    amount,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(AppIcons.next),
          ],
        ),
      ),
    );
  }
}
