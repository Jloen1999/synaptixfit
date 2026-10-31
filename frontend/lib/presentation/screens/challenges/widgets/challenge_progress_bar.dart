import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Barra de progreso 0-1 con porcentaje y descripción accesible.
class ChallengeProgressBar extends StatelessWidget {
  const ChallengeProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.showLabel = true,
  });

  final double value;
  final Color color;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Semantics(
      label: context.localizations.challengesProgressSemantics(percent),
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TokensRadius.pill),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1).toDouble(),
                color: color,
                backgroundColor: color.withValues(alpha: AppPill.tintAlpha),
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: TokensSpacing.s),
            Text(
              context.localizations.challengesProgressPercent(percent),
              style: context.textStyles.labelLarge,
            ),
          ],
        ],
      ),
    );
  }
}
