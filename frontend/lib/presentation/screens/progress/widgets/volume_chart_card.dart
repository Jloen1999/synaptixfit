import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/progress/training_volume.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import 'chart_card.dart';
import 'chart_style.dart';
import 'progress_labels.dart';

enum _VolumeMetric { minutes, calories }

/// Volumen semanal en barras; alterna entre minutos y calorías.
class VolumeChartCard extends StatefulWidget {
  const VolumeChartCard({super.key, required this.volume});

  final TrainingVolume volume;

  @override
  State<VolumeChartCard> createState() => _VolumeChartCardState();
}

class _VolumeChartCardState extends State<VolumeChartCard> {
  _VolumeMetric _metric = _VolumeMetric.minutes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final volume = widget.volume;
    final points = volume.points;
    final hasData = points.any((p) => p.minutes > 0 || p.calories > 0);
    final minutes = _metric == _VolumeMetric.minutes;
    final values = [
      for (final p in points) (minutes ? p.minutes : p.calories).toDouble(),
    ];
    final best = values.fold<double>(0, (m, v) => v > m ? v : m);
    final average = minutes
        ? volume.averageMinutesPerWeek
        : volume.averageCaloriesPerWeek;
    final metricLabel = minutes
        ? l10n.progressVolumeMinutesLabel
        : l10n.progressVolumeCaloriesLabel;
    final color = minutes ? context.colors.secondary : context.palette.calories;

    return ChartCard(
      title: l10n.progressVolumeTitle,
      subtitle: l10n.progressVolumeSubtitle,
      semanticsSummary: hasData
          ? l10n.progressVolumeSemantics(
              metricLabel,
              ProgressFormat.integer(average),
              ProgressFormat.integer(best),
            )
          : null,
      footer: hasData
          ? Text(
              l10n.progressVolumeAverage(
                ProgressFormat.integer(volume.averageMinutesPerWeek),
                ProgressFormat.integer(volume.averageCaloriesPerWeek),
                ProgressFormat.oneDecimal(volume.averageSessionsPerWeek),
              ),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            )
          : null,
      child: !hasData
          ? InlineNotice(
              icon: Icons.bar_chart_rounded,
              message: l10n.progressVolumeEmpty,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SegmentedButton<_VolumeMetric>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    ButtonSegment(
                      value: _VolumeMetric.minutes,
                      label: Text(l10n.progressMetricMinutes),
                    ),
                    ButtonSegment(
                      value: _VolumeMetric.calories,
                      label: Text(l10n.progressMetricCalories),
                    ),
                  ],
                  selected: {_metric},
                  onSelectionChanged: (s) => setState(() => _metric = s.first),
                ),
                const SizedBox(height: TokensSpacing.m),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: best <= 0 ? 1 : best * 1.15,
                      borderData: FlBorderData(show: false),
                      gridData: ChartStyle.grid(context),
                      titlesData: ChartStyle.titles(
                        context,
                        bottom: (i) => i >= 0 && i < points.length
                            ? ProgressFormat.week(points[i].weekStart)
                            : null,
                        count: points.length,
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => context.colors.inverseSurface,
                          getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                            ProgressFormat.integer(rod.toY),
                            context.textStyles.labelMedium!.copyWith(
                              color: context.colors.onInverseSurface,
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < values.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: values[i],
                                color: color,
                                width: points.length > 14 ? 6 : 14,
                                borderRadius: BorderRadius.circular(
                                  TokensRadius.s / 2,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    duration: ChartStyle.duration(context),
                  ),
                ),
              ],
            ),
    );
  }
}
