import 'package:flutter/material.dart' hide Badge;

import '../../../../domain/models/progress/badge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';

/// Resultado de la celebración de logros.
enum AchievementDialogResult { closed, seeBadges }

/// Celebración única de una subida de nivel y/o insignias nuevas, la muestre
/// la acción que la muestre ([AchievementsHost]).
class AchievementDialog extends StatelessWidget {
  const AchievementDialog({super.key, this.level, required this.badges});

  final int? level;
  final List<Badge> badges;

  static Future<AchievementDialogResult> show(
    BuildContext context, {
    int? level,
    required List<Badge> badges,
  }) async =>
      await showDialog<AchievementDialogResult>(
        context: context,
        builder: (_) => AchievementDialog(level: level, badges: badges),
      ) ??
      AchievementDialogResult.closed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final level = this.level;
    final title = level != null
        ? l10n.achievementLevelTitle(level)
        : l10n.achievementBadgesTitle(badges.length);
    final message = level != null
        ? l10n.achievementLevelMessage
        : l10n.achievementBadgesMessage;
    return AlertDialog(
      icon: _Emblem(level: level),
      title: Semantics(
        liveRegion: true,
        child: Text(title, textAlign: TextAlign.center),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, textAlign: TextAlign.center),
              if (level != null && badges.isNotEmpty) ...[
                const SizedBox(height: TokensSpacing.l),
                Text(
                  l10n.achievementBadgesTitle(badges.length),
                  style: context.textStyles.titleSmall,
                ),
              ],
              if (badges.isNotEmpty) const SizedBox(height: TokensSpacing.sm),
              for (final badge in badges) _BadgeRow(badge: badge),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (badges.isNotEmpty)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(AchievementDialogResult.seeBadges),
            child: Text(l10n.achievementSeeBadges),
          ),
        FilledButton(
          autofocus: true,
          onPressed: () =>
              Navigator.of(context).pop(AchievementDialogResult.closed),
          child: Text(l10n.achievementClose),
        ),
      ],
    );
  }
}

/// Medallón con el nivel alcanzado (o un trofeo si solo hay insignias). Entra
/// con un pequeño rebote salvo que el sistema pida reducir el movimiento.
class _Emblem extends StatelessWidget {
  const _Emblem({this.level});

  final int? level;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final level = this.level;
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: context.reduceMotion ? 1 : 0.6, end: 1),
        duration: context.motion(TokensDuration.slow),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: context.scaled(TokensSize.medallion),
          height: context.scaled(TokensSize.medallion),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.accentContainer,
            border: Border.all(color: palette.accent, width: 3),
          ),
          child: level != null
              ? Text(
                  '$level',
                  style: context.textStyles.headlineLarge?.copyWith(
                    color: palette.onAccentContainer,
                  ),
                )
              : Icon(
                  Icons.emoji_events_rounded,
                  size: context.scaled(TokensSize.medallion / 2),
                  color: palette.onAccentContainer,
                ),
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.badge});

  final Badge badge;

  @override
  Widget build(BuildContext context) {
    final description = badge.description;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: MergeSemantics(
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: context.palette.accentContainer,
              // Siempre un icono del sistema: los emojis cambian de aspecto
              // según la plataforma y el lector los lee de forma irregular.
              child: Icon(
                Icons.military_tech_rounded,
                color: context.palette.onAccentContainer,
              ),
            ),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(badge.name, style: context.textStyles.titleSmall),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
