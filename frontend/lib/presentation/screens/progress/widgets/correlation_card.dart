import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../domain/enums/analytics_enums.dart';
import '../../../../domain/models/progress/load_correlation.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import 'chart_card.dart';
import 'chart_style.dart';
import 'progress_labels.dart';

/// Correlación estudio ↔ entrenamiento en dispersión, con coeficiente, fuerza
/// y dirección. Permite alternar la métrica de entrenamiento (RPE / minutos).
class CorrelationCard extends StatelessWidget {
  const CorrelationCard({
    super.key,
    required this.correlation,
    required this.metric,
    required this.loading,
    required this.onMetricChanged,
  });

  final LoadCorrelation correlation;

  /// Métrica seleccionada (puede ir por delante de los datos mientras carga).
  final CorrelationMetric metric;
  final bool loading;
  final ValueChanged<CorrelationMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final c = correlation;
    final coefficient = c.coefficient;
    final label = l10n.correlationLabel(c.strength, c.direction);
    final selector = Tooltip(
      message: l10n.progressCorrelationMetricTooltip,
      child: SegmentedButton<CorrelationMetric>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: [
          for (final m in CorrelationMetric.values)
            ButtonSegment(value: m, label: Text(l10n.correlationMetric(m))),
        ],
        selected: {metric},
        onSelectionChanged: loading ? null : (s) => onMetricChanged(s.first),
      ),
    );

    return ChartCard(
      title: l10n.progressCorrelationTitle,
      subtitle: c.metric == CorrelationMetric.rpe
          ? l10n.progressCorrelationSubtitleRpe
          : l10n.progressCorrelationSubtitleMinutes,
      semanticsSummary: c.sufficientData && coefficient != null
          ? l10n.progressCorrelationSemantics(
              c.sampleSize,
              ProgressFormat.signed(coefficient),
              label,
            )
          : null,
      footer: c.sufficientData && coefficient != null
          ? Wrap(
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: Icon(
                    _directionIcon(c.direction, c.strength),
                    size: 18,
                    color: context.colors.primary,
                  ),
                  label: Text(
                    l10n.progressCorrelationCoefficient(
                      ProgressFormat.signed(coefficient),
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Text(label, style: context.textStyles.bodyMedium),
              ],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          selector,
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: TokensSpacing.s),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: TokensSpacing.m),
          if (!c.sufficientData)
            InlineNotice(
              icon: Icons.scatter_plot_outlined,
              // Con semanas suficientes y sin coeficiente, el problema es que
              // los valores no varían (p. ej. siempre el mismo RPE).
              message: c.sampleSize >= c.minimumSampleSize
                  ? l10n.progressCorrelationNoVariation
                  : l10n.progressCorrelationInsufficient(
                      c.minimumSampleSize,
                      c.sampleSize,
                    ),
            )
          else
            SizedBox(height: 220, child: _Scatter(correlation: c)),
        ],
      ),
    );
  }

  static IconData _directionIcon(
    CorrelationDirection? direction,
    CorrelationStrength? strength,
  ) {
    if (strength == null || strength == CorrelationStrength.none) {
      return Icons.horizontal_rule_rounded;
    }
    return direction == CorrelationDirection.negative
        ? Icons.south_east_rounded
        : Icons.north_east_rounded;
  }
}

class _Scatter extends StatelessWidget {
  const _Scatter({required this.correlation});

  final LoadCorrelation correlation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final points = correlation.points;
    final color = context.palette.study;
    double maxOf(Iterable<double> values) =>
        values.fold<double>(0, (m, v) => v > m ? v : m);
    final maxX = maxOf(points.map((p) => p.studyHours));
    final maxY = correlation.metric == CorrelationMetric.rpe
        ? 10.0
        : maxOf(points.map((p) => p.trainingValue));
    return Column(
      children: [
        Expanded(
          child: ScatterChart(
            ScatterChartData(
              minX: 0,
              minY: 0,
              maxX: maxX <= 0 ? 1 : maxX * 1.1,
              maxY: maxY <= 0 ? 1 : maxY * 1.1,
              borderData: FlBorderData(show: false),
              gridData: ChartStyle.grid(context),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    l10n.correlationMetric(correlation.metric),
                    style: context.textStyles.labelSmall,
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => value == meta.max
                        ? const SizedBox.shrink()
                        : SideTitleWidget(
                            meta: meta,
                            child: Text(
                              meta.formattedValue,
                              style: context.textStyles.labelSmall,
                            ),
                          ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    l10n.progressCorrelationAxisStudy,
                    style: context.textStyles.labelSmall,
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) => value == meta.max
                        ? const SizedBox.shrink()
                        : SideTitleWidget(
                            meta: meta,
                            child: Text(
                              meta.formattedValue,
                              style: context.textStyles.labelSmall,
                            ),
                          ),
                  ),
                ),
              ),
              scatterTouchData: ScatterTouchData(
                touchTooltipData: ScatterTouchTooltipData(
                  getTooltipColor: (_) => context.colors.inverseSurface,
                  getTooltipItems: (spot) => ScatterTooltipItem(
                    '${ProgressFormat.oneDecimal(spot.x)} h · '
                    '${ProgressFormat.oneDecimal(spot.y)}',
                    textStyle: context.textStyles.labelMedium!.copyWith(
                      color: context.colors.onInverseSurface,
                    ),
                  ),
                ),
              ),
              scatterSpots: [
                for (final p in points)
                  ScatterSpot(
                    p.studyHours,
                    p.trainingValue,
                    dotPainter: FlDotCirclePainter(
                      radius: 6,
                      color: color.withValues(alpha: 0.75),
                      strokeWidth: 1.5,
                      strokeColor: color,
                    ),
                  ),
              ],
            ),
            duration: ChartStyle.duration(context),
          ),
        ),
      ],
    );
  }
}
