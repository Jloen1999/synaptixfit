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
        // Wrap: con el texto al 200 % la cifra baja de línea en vez de
        // partir «Nivel 14» letra a letra.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: TokensSpacing.s,
          children: [
            Text(
              context.localizations.commonLevel(level),
              style: context.textStyles.labelLarge,
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
          // El valor del lector es numérico (porcentaje); la cifra de XP va
          // en la etiqueta.
          semanticsLabel:
              '${context.localizations.commonLevel(level)}, '
              '${context.localizations.commonXpProgress(levelXp, levelThreshold)}',
          value: progress,
          color: context.palette.accent,
          backgroundColor: context.palette.accentContainer,
        ),
      ],
    );
  }
}
