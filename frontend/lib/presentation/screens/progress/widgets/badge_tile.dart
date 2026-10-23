import 'package:flutter/material.dart' hide Badge;

import '../../../../domain/models/progress/badge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'progress_labels.dart';

/// Matriz de escala de grises para las insignias bloqueadas (valor técnico).
const _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 0.6, 0, //
]);

/// Emoji de la insignia sobre un círculo del color de su rareza.
class BadgeEmblem extends StatelessWidget {
  const BadgeEmblem({super.key, required this.badge, this.size = 56});

  final Badge badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.rarityColor(badge.rarity);
    final emblem = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: badge.earned
            ? color.withValues(alpha: 0.16)
            : context.colors.surfaceContainer,
        border: Border.all(
          color: badge.earned ? color : context.colors.outlineVariant,
          width: 2,
        ),
      ),
      child: Text(
        badge.icon.isEmpty ? '🏅' : badge.icon,
        style: TextStyle(fontSize: size * 0.48),
      ),
    );
    if (badge.earned) return emblem;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ColorFiltered(colorFilter: _greyscale, child: emblem),
        Positioned(
          right: -2,
          bottom: -2,
          child: CircleAvatar(
            radius: size * 0.17,
            backgroundColor: context.colors.surfaceContainerHigh,
            child: Icon(
              Icons.lock_rounded,
              size: size * 0.2,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Celda de la cuadrícula de insignias (obtenida en color; bloqueada en gris
/// con candado y progreso).
class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge, required this.onTap});

  final Badge badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final earnedAt = badge.earnedAt;
    final semantics = badge.earned
        ? l10n.progressBadgeSemanticsEarned(badge.name)
        : l10n.progressBadgeSemanticsLocked(
            badge.name,
            (badge.progress * 100).round(),
          );
    // La etiqueta va dentro de la tarjeta para fusionarse con su InkWell
    // (acción y foco); por fuera la taparía.
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(TokensSpacing.s + TokensSpacing.xs),
      child: Semantics(
        button: true,
        label: semantics,
        excludeSemantics: true,
        child: Column(
          children: [
            BadgeEmblem(badge: badge),
            const SizedBox(height: TokensSpacing.s),
            Text(
              badge.name,
              style: context.textStyles.titleSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: TokensSpacing.xxs),
            Text(
              l10n.badgeRarity(badge.rarity),
              style: context.textStyles.labelSmall?.copyWith(
                color: badge.earned
                    ? context.rarityColor(badge.rarity)
                    : context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (badge.earned)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!badge.visible) ...[
                    Icon(
                      Icons.visibility_off_outlined,
                      size: 14,
                      color: context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: TokensSpacing.xxs),
                  ],
                  Flexible(
                    child: Text(
                      earnedAt == null
                          ? l10n.progressBadgeEarned
                          : l10n.progressBadgeEarnedOn(
                              ProgressFormat.date(earnedAt),
                            ),
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ],
              )
            else
              BadgeProgressBar(badge: badge, compact: true),
          ],
        ),
      ),
    );
  }
}

/// Progreso de una insignia bloqueada hacia su criterio.
class BadgeProgressBar extends StatelessWidget {
  const BadgeProgressBar({
    super.key,
    required this.badge,
    this.compact = false,
  });

  final Badge badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = badge.currentValue.clamp(0, badge.criterionValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(TokensRadius.pill),
          child: LinearProgressIndicator(
            value: badge.progress,
            color: context.colors.primary,
            backgroundColor: context.colors.surfaceContainerHigh,
          ),
        ),
        const SizedBox(height: TokensSpacing.xxs),
        Text(
          context.localizations.progressBadgeProgressValue(
            current,
            badge.criterionValue,
          ),
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: compact ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }
}
