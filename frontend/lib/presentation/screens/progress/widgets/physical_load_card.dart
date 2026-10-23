import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/progress/physical_load.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import 'chart_card.dart';
import 'progress_labels.dart';

/// Carga física diaria de los últimos 28 días (gráfica pequeña).
class PhysicalLoadCard extends StatelessWidget {
  const PhysicalLoadCard({super.key, required this.load});

  /// Nulo si no se pudo cargar.
  final PhysicalLoad? load;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final data = load;
    if (data == null || !data.hasData) {
      return ChartCard(
        title: l10n.progressLoadTitle,
        subtitle: l10n.progressLoadSubtitle,
        child: InlineNotice(
          icon: data == null
              ? Icons.cloud_off_rounded
              : Icons.show_chart_rounded,
          message: data == null
              ? l10n.progressSectionUnavailable
              : l10n.progressLoadEmpty,
        ),
      );
    }
    final today = ProgressFormat.integer(data.todayLoad);
    final max = ProgressFormat.integer(data.maxDailyLoad);
    final average = ProgressFormat.integer(data.averageLoad);
    return ChartCard(
      title: l10n.progressLoadTitle,
      subtitle: l10n.progressLoadSubtitle,
      semanticsSummary: l10n.progressLoadSemantics(today, max, average),
      footer: Text(
        l10n.progressLoadSummary(today, max, average),
        style: context.textStyles.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      child: SizedBox(height: 96, child: _LoadBars(load: data)),
    );
  }
}

class _LoadBars extends StatelessWidget {
  const _LoadBars({required this.load});

  final PhysicalLoad load;

  @override
  Widget build(BuildContext context) {
    final days = load.last28Days;
    final highest = days.fold<double>(
      load.maxDailyLoad,
      (m, d) => d.load > m ? d.load : m,
    );
    final color = context.colors.secondary;
    return BarChart(
      BarChartData(
        maxY: highest <= 0 ? 1 : highest * 1.1,
        alignment: BarChartAlignment.spaceBetween,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => context.colors.inverseSurface,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${ProgressFormat.week(days[group.x].date)}\n'
              '${ProgressFormat.integer(rod.toY)}',
              context.textStyles.labelSmall!.copyWith(
                color: context.colors.onInverseSurface,
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].load,
                  width: 6,
                  borderRadius: BorderRadius.circular(TokensRadius.s / 2),
                  // El último día (hoy) se resalta.
                  color: i == days.length - 1
                      ? context.palette.accent
                      : color.withValues(alpha: 0.7),
                ),
              ],
            ),
        ],
      ),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : TokensDuration.normal,
    );
  }
}
