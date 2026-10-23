import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Barra de progreso del nivel actual.
class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.level,
    required this.levelXp,
    required this.levelThreshold,
  });

  final int level;
  final int levelXp;
  final int levelThreshold;

  @override
  Widget build(BuildContext context) {
    final progress = levelThreshold == 0
        ? 0.0
        : (levelXp / levelThreshold).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.localizations.commonLevel(level),
                style: context.textStyles.labelLarge,
              ),
            ),
            Text(
              context.localizations.commonXpProgress(levelXp, levelThreshold),
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensSpacing.xs),
        // Grosor y radio del tema (`progressIndicatorTheme`).
        LinearProgressIndicator(
          value: progress,
          color: context.palette.accent,
          backgroundColor: context.palette.accentContainer,
        ),
      ],
    );
  }
}
