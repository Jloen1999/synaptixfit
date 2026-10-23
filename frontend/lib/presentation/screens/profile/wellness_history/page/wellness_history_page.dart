import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/profile/wellness_history.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/profile_labels.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/wellness_history_bloc.dart';

/// Historial de peso (gráfica) y de objetivos (`/profile/wellness-history`).
class WellnessHistoryPage extends StatelessWidget {
  const WellnessHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<WellnessHistoryBloc>()
            ..add(const WellnessHistoryEvent.started()),
      child: const _WellnessHistoryView(),
    );
  }
}

class _WellnessHistoryView extends StatelessWidget {
  const _WellnessHistoryView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar.reading(title: Text(l10n.profileWellnessHistoryTitle)),
      body: BlocBuilder<WellnessHistoryBloc, WellnessHistoryState>(
        builder: (context, state) {
          final bloc = context.read<WellnessHistoryBloc>();
          switch (state.status) {
            case WellnessHistoryStatus.loading:
              return const AppSkeletonGroup(
                child: ProfileScrollBody(
                  children: [
                    AppSkeleton(height: 240),
                    SizedBox(height: TokensSpacing.m),
                    AppSkeleton(height: 72),
                    SizedBox(height: TokensSpacing.s),
                    AppSkeleton(height: 72),
                  ],
                ),
              );
            case WellnessHistoryStatus.failure:
              return AppErrorView(
                error: state.error!,
                onRetry: () => bloc.add(const WellnessHistoryEvent.started()),
              );
            case WellnessHistoryStatus.ready:
              return RefreshIndicator(
                onRefresh: () async =>
                    bloc.add(const WellnessHistoryEvent.started()),
                child: ProfileScrollBody(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    AppSectionHeader(title: l10n.profileWeightHistoryTitle),
                    if (state.weights.isEmpty)
                      AppEmptyState(
                        icon: Icons.monitor_weight_outlined,
                        title: l10n.profileWeightHistoryEmpty,
                        message: l10n.profileWeightHistoryEmptyHint,
                      )
                    else
                      _WeightChart(records: state.weights),
                    const SizedBox(height: TokensSpacing.l),
                    AppSectionHeader(title: l10n.profileGoalHistoryTitle),
                    if (state.goals.isEmpty)
                      AppEmptyState(
                        icon: Icons.flag_outlined,
                        title: l10n.profileGoalHistoryEmpty,
                      )
                    else
                      for (final entry in state.goals)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: TokensSpacing.s,
                          ),
                          child: _GoalEntryTile(entry: entry),
                        ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.records});

  /// En orden cronológico.
  final List<WeightRecord> records;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final number = NumberFormat('0.#', 'es');
    final dayFormat = DateFormat.MMMd('es');
    final color = context.colors.secondary;
    final weights = records.map((r) => r.weightKg).toList();
    final minY = (weights.reduce((a, b) => a < b ? a : b) - 2).floorToDouble();
    final maxY = (weights.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble();
    final last = records.last;
    final first = records.first;
    final delta = last.weightKg - first.weightKg;
    final spots = [
      for (var i = 0; i < records.length; i++)
        FlSpot(i.toDouble(), records[i].weightKg),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileKgValue(number.format(last.weightKg)),
                      style: context.textStyles.headlineSmall,
                    ),
                    Text(
                      l10n.profileWeightLastRecord(
                        dayFormat.format(last.recordedAt),
                      ),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (records.length > 1)
                Text(
                  l10n.profileWeightDelta(
                    '${delta > 0 ? '+' : ''}${number.format(delta)}',
                  ),
                  style: context.textStyles.labelLarge,
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          Semantics(
            label: l10n.profileWeightChartSemantics(
              records.length,
              number.format(first.weightKg),
              number.format(last.weightKg),
            ),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: 0,
                  maxX: (records.length - 1).toDouble().clamp(
                    1,
                    double.infinity,
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: context.colors.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            number.format(value),
                            style: context.textStyles.labelSmall,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (records.length / 4).ceilToDouble().clamp(
                          1,
                          double.infinity,
                        ),
                        getTitlesWidget: (value, meta) {
                          final i = value.round();
                          if (i < 0 ||
                              i >= records.length ||
                              value != i.toDouble()) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              dayFormat.format(records[i].recordedAt),
                              style: context.textStyles.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          context.colors.surfaceContainerHigh,
                      getTooltipItems: (spots) => [
                        for (final spot in spots)
                          LineTooltipItem(
                            '${l10n.profileKgValue(number.format(spot.y))}\n'
                            '${dayFormat.format(records[spot.x.round()].recordedAt)}',
                            context.textStyles.labelMedium!,
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: records.length <= 20),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
                duration: context.motion(TokensDuration.slow),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalEntryTile extends StatelessWidget {
  const _GoalEntryTile({required this.entry});

  final GoalHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final format = DateFormat.yMMMd('es');
    final title = entry.goal?.label(l10n) ?? entry.goalLabel ?? '—';
    final start = entry.startDate == null
        ? '—'
        : format.format(entry.startDate!);
    final period = entry.active
        ? l10n.profileGoalSince(start)
        : l10n.profileGoalPeriod(
            start,
            entry.endDate == null ? '—' : format.format(entry.endDate!),
          );
    final previous = entry.previousGoal?.label(l10n) ?? entry.previousGoalLabel;
    return AppCard(
      child: Row(
        children: [
          Icon(
            entry.goal?.icon ?? Icons.flag_outlined,
            color: entry.active
                ? context.colors.secondary
                : context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleSmall),
                Text(
                  period,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                if (previous != null)
                  Text(
                    l10n.profileGoalPrevious(previous),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (entry.active)
            Chip(
              label: Text(l10n.profileGoalActive),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
