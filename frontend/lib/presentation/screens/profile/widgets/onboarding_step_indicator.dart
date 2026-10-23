import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';

/// Indicador de pasos del onboarding: barra segmentada y «Paso X de Y».
class OnboardingStepIndicator extends StatelessWidget {
  const OnboardingStepIndicator({
    super.key,
    required this.current,
    required this.total,
    required this.title,
  });

  /// Índice del paso actual (desde 0).
  final int current;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Semantics(
      label: l10n.profileOnboardingStepOf(current + 1, total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: TokensSpacing.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: context.motion(TokensDuration.normal),
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= current
                          ? context.colors.primary
                          : context.colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(TokensRadius.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          ExcludeSemantics(
            child: Text(
              l10n.profileOnboardingStepOf(current + 1, total),
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: TokensSpacing.xxs),
          Text(title, style: context.textStyles.headlineSmall),
        ],
      ),
    );
  }
}
