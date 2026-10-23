import 'package:flutter/material.dart';

import '../../../../domain/enums/analytics_enums.dart';
import '../../../../domain/models/progress/analytics_insight.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'insight_texts.dart';

/// Tarjeta de interpretación con icono y color según la severidad (y el tono
/// también en texto para no depender solo del color).
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight, required this.text});

  final AnalyticsInsight insight;
  final InsightText text;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final (icon, color, tone) = switch (insight.severity) {
      InsightSeverity.positive => (
        Icons.check_circle_rounded,
        context.palette.success,
        l10n.progressInsightSeverityPositive,
      ),
      InsightSeverity.info => (
        Icons.info_rounded,
        context.colors.primary,
        l10n.progressInsightSeverityInfo,
      ),
      InsightSeverity.warning => (
        Icons.warning_amber_rounded,
        context.palette.warning,
        l10n.progressInsightSeverityWarning,
      ),
    };
    return Semantics(
      container: true,
      label: '$tone. ${text.title}. ${text.message}',
      excludeSemantics: true,
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(TokensSpacing.s),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(TokensRadius.m),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          text.title,
                          style: context.textStyles.titleSmall,
                        ),
                      ),
                      Text(
                        tone,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensSpacing.xs),
                  Text(text.message, style: context.textStyles.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
