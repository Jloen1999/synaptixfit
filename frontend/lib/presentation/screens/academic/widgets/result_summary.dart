import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Resumen de un resultado: aciertos, porcentaje y XP ganada.
class ResultSummary extends StatelessWidget {
  const ResultSummary({
    super.key,
    required this.title,
    required this.correct,
    required this.total,
    required this.xp,
    this.extra,
  });

  final String title;
  final int correct;
  final int total;
  final int xp;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final ratio = total == 0 ? 0.0 : correct / total;
    final color = ratio >= 0.7
        ? context.palette.success
        : ratio >= 0.5
        ? context.palette.warning
        : context.colors.error;
    return Column(
      children: [
        Text(
          title,
          style: context.textStyles.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TokensSpacing.l),
        SizedBox.square(
          dimension: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: ratio,
                strokeWidth: 12,
                color: color,
                backgroundColor: color.withValues(alpha: 0.16),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(ratio * 100).round()}%',
                      style: context.textStyles.headlineMedium,
                    ),
                    Text(
                      l10n.academicResultCorrect(correct, total),
                      style: context.textStyles.labelMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensSpacing.l),
        AppPill(
          label: xp > 0 ? l10n.academicXpEarned(xp) : l10n.academicXpNone,
          color: context.palette.accent,
          icon: Icons.bolt_rounded,
        ),
        if (extra != null) ...[const SizedBox(height: TokensSpacing.m), extra!],
      ],
    );
  }
}
