import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../domain/enums/analytics_enums.dart';
import '../../../../domain/models/progress/rpe_trend.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import 'chart_card.dart';
import 'chart_style.dart';
import 'progress_labels.dart';

import '../../../theme/app_icons.dart';

/// Tendencia semanal del RPE en línea, con la dirección de la tendencia.
class RpeTrendCard extends StatelessWidget {
  const RpeTrendCard({super.key, required this.trend});

  final RpeTrend trend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final points = trend.points;
    final color = context.colors.tertiary;
    final slope = trend.slopePerWeek;
    final direction = l10n.trendDirection(trend.direction);
    return ChartCard(
      title: l10n.progressRpeTitle,
      subtitle: l10n.progressRpeSubtitle,
      semanticsSummary: points.isEmpty
          ? null
          : l10n.progressRpeSemantics(
              ProgressFormat.oneDecimal(points.last.averageRpe),
              direction,
            ),
      footer: points.isEmpty
          ? null
          : Wrap(
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _DirectionChip(direction: trend.direction, label: direction),
                if (slope != null &&
                    trend.direction != TrendDirection.insufficientData)
                  Text(
                    l10n.progressRpeSlope(ProgressFormat.signed(slope)),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
      child: points.isEmpty
          ? InlineNotice(
              icon: Icons.show_chart_rounded,
              message: l10n.progressRpeEmpty,
            )
          : SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 10,
                  minX: 0,
                  maxX: points.length <= 1 ? 1 : (points.length - 1).toDouble(),
                  borderData: FlBorderData(show: false),
                  gridData: ChartStyle.grid(context),
                  titlesData: ChartStyle.titles(
                    context,
                    bottom: (i) => i >= 0 && i < points.length
                        ? ProgressFormat.week(points[i].weekStart)
                        : null,
                    count: points.length,
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => context.colors.inverseSurface,
                      getTooltipItems: (spots) => [
                        for (final s in spots)
                          LineTooltipItem(
                            ProgressFormat.oneDecimal(s.y),
                            context.textStyles.labelMedium!.copyWith(
                              color: context.colors.onInverseSurface,
                            ),
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].averageRpe),
                      ],
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
                duration: ChartStyle.duration(context),
              ),
            ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  const _DirectionChip({required this.direction, required this.label});

  final TrendDirection direction;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Subir o bajar el RPE no es bueno ni malo por sí solo: color neutro.
    final (icon, color) = switch (direction) {
      TrendDirection.up => (Icons.trending_up_rounded, context.colors.primary),
      TrendDirection.down => (
        Icons.trending_down_rounded,
        context.colors.primary,
      ),
      TrendDirection.stable => (
        Icons.trending_flat_rounded,
        context.colors.primary,
      ),
      TrendDirection.insufficientData => (
        AppIcons.help,
        context.colors.onSurfaceVariant,
      ),
    };
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
