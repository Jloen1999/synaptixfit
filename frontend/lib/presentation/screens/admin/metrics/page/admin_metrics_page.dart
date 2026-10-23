import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/admin/platform_metrics.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/admin_status.dart';
import '../../widgets/admin_widgets.dart';
import '../bloc/admin_metrics_bloc.dart';

/// Pestaña KPIs del panel.
class AdminMetricsTab extends StatelessWidget {
  const AdminMetricsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AdminMetricsBloc>()..add(const AdminMetricsEvent.started()),
      child: const AdminMetricsView(),
    );
  }
}

/// Vista de los KPIs; separada de [AdminMetricsTab] para probarla con un bloc simulado.
class AdminMetricsView extends StatelessWidget {
  const AdminMetricsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminMetricsBloc, AdminMetricsState>(
      builder: (context, state) {
        final bloc = context.read<AdminMetricsBloc>();
        if (state.status == AdminStatus.failure && state.metrics == null) {
          return AppErrorView(
            error: state.error!,
            onRetry: () => bloc.add(const AdminMetricsEvent.started()),
          );
        }
        final metrics = state.metrics;
        if (metrics == null) return const AppSkeletonList(count: 6, height: 96);
        return RefreshIndicator(
          onRefresh: () async {
            bloc.add(const AdminMetricsEvent.refreshed());
            await bloc.stream.firstWhere((s) => !s.status.isLoading);
          },
          child: ListView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            children: [
              AdminContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _KpiGrid(metrics: metrics),
                    const SizedBox(height: TokensSpacing.l),
                    _TrendCard(state: state),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.metrics});

  final PlatformMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    final palette = context.palette;
    final tiles = [
      (
        Icons.people_alt_rounded,
        colors.primary,
        metrics.totalUsers,
        l10n.adminKpiTotalUsers,
      ),
      (
        Icons.bolt_rounded,
        palette.success,
        metrics.activeUsersToday,
        l10n.adminKpiActiveToday,
      ),
      (
        Icons.fitness_center_rounded,
        colors.secondary,
        metrics.trainingSessionsToday,
        l10n.adminKpiSessionsToday,
      ),
      (
        Icons.list_alt_rounded,
        palette.sessions,
        metrics.activeRoutines,
        l10n.adminKpiActiveRoutines,
      ),
      (
        Icons.flag_rounded,
        palette.accent,
        metrics.activeChallenges,
        l10n.adminKpiActiveChallenges,
      ),
      (
        Icons.report_outlined,
        colors.error,
        metrics.pendingReportedContent,
        l10n.adminKpiReported,
      ),
      (
        Icons.person_add_alt_1_rounded,
        colors.tertiary,
        metrics.newUsersToday,
        l10n.adminKpiNewToday,
      ),
      (
        Icons.visibility_off_outlined,
        palette.warning,
        metrics.shadowbannedUsers,
        l10n.adminKpiShadowbanned,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 3
            : 2;
        const gap = TokensSpacing.s;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (icon, color, value, label) in tiles)
              SizedBox(
                width: width,
                child: AppMetricTile(
                  icon: icon,
                  color: color,
                  value: AdminFormat.number(value),
                  label: label,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Una línea de la tendencia: además del color, cada una lleva su propio trazo
/// (continuo, discontinuo o punteado) para distinguirlas sin ver colores (1.4.1).
typedef _TrendSeries = ({
  String label,
  Color color,
  List<int>? dash,
  int Function(DailyActivity) value,
});

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.state});

  final AdminMetricsState state;

  static const _dayOptions = [7, 30, 90];

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    final List<_TrendSeries> series = [
      (
        label: l10n.adminTrendSignups,
        color: colors.tertiary,
        dash: const [8, 4],
        value: (d) => d.signups,
      ),
      (
        label: l10n.adminTrendActive,
        color: colors.primary,
        dash: null,
        value: (d) => d.activeUsers,
      ),
      (
        label: l10n.adminTrendSessions,
        color: colors.secondary,
        dash: const [2, 4],
        value: (d) => d.trainingSessions,
      ),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: TokensSpacing.m,
            runSpacing: TokensSpacing.s,
            children: [
              Text(l10n.adminTrendTitle, style: context.textStyles.titleMedium),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (final days in _dayOptions)
                    ButtonSegment(
                      value: days,
                      label: Text(l10n.adminTrendDays(days)),
                    ),
                ],
                selected: {state.trendDays},
                onSelectionChanged: (selection) => context
                    .read<AdminMetricsBloc>()
                    .add(AdminMetricsEvent.trendDaysChanged(selection.first)),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.m,
            children: [
              for (final s in series)
                _LegendItem(label: s.label, color: s.color, dash: s.dash),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          SizedBox(
            height: 240,
            child: state.trendLoading
                ? const AppLoadingView()
                : state.trendError != null
                ? AppErrorView(
                    error: state.trendError!,
                    onRetry: () => context.read<AdminMetricsBloc>().add(
                      AdminMetricsEvent.trendDaysChanged(state.trendDays),
                    ),
                  )
                : state.trend.isEmpty
                ? Center(child: Text(l10n.adminTrendEmpty))
                : AppChartSummary(
                    summary: _summary(context, series),
                    child: _TrendChart(trend: state.trend, series: series),
                  ),
          ),
        ],
      ),
    );
  }

  /// Periodo y, por cada línea, último día, máximo y media diaria.
  String _summary(BuildContext context, List<_TrendSeries> series) {
    final l10n = context.localizations;
    final trend = state.trend;
    final parts = <String>[];
    for (final s in series) {
      final values = trend.map(s.value).toList();
      final total = values.fold<int>(0, (a, b) => a + b);
      parts.add(
        l10n.adminTrendSeriesSummary(
          s.label,
          AdminFormat.number(values.last),
          AdminFormat.number(values.fold<int>(0, math.max)),
          AdminFormat.decimal(total / values.length),
        ),
      );
    }
    return l10n.adminTrendSemantics(
      state.trendDays,
      AdminFormat.shortDate(trend.first.date),
      AdminFormat.shortDate(trend.last.date),
      parts.join('; '),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color, this.dash});

  final String label;
  final Color color;
  final List<int>? dash;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CustomPaint(
        size: const Size(24, 4),
        painter: _LegendLinePainter(color: color, dash: dash),
      ),
      const SizedBox(width: TokensSpacing.xs),
      Text(label, style: context.textStyles.labelMedium),
    ],
  );
}

/// Muestra de la línea en la leyenda con el mismo trazo que en la gráfica.
class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter({required this.color, this.dash});

  final Color color;
  final List<int>? dash;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;
    final pattern = dash ?? [size.width.ceil()];
    var x = 0.0;
    // Alterna tramo pintado / hueco igual que `dashArray` de fl_chart.
    for (var i = 0; x < size.width; i++) {
      final length = pattern[i % pattern.length].toDouble();
      if (i.isEven) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + length, size.width), y),
          paint,
        );
      }
      x += length;
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter old) =>
      old.color != color || old.dash != dash;
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.trend, required this.series});

  final List<DailyActivity> trend;
  final List<_TrendSeries> series;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labelStyle = context.textStyles.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final maxY = trend
        .expand((d) => [for (final s in series) s.value(d)])
        .fold<int>(0, math.max);
    final step = math.max(1, (trend.length / 6).ceil());
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxY == 0 ? 1 : maxY * 1.15).toDouble(),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colors.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => value % 1 == 0
                  ? Text(value.toInt().toString(), style: labelStyle)
                  : const SizedBox.shrink(),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= trend.length || index % step != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: TokensSpacing.xs),
                  child: Text(
                    AdminFormat.shortDate(trend[index].date),
                    style: labelStyle,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          for (final s in series)
            LineChartBarData(
              spots: [
                for (var i = 0; i < trend.length; i++)
                  FlSpot(i.toDouble(), s.value(trend[i]).toDouble()),
              ],
              color: s.color,
              barWidth: 2.5,
              dashArray: s.dash,
              isCurved: true,
              preventCurveOverShooting: true,
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
      duration: context.motion(TokensDuration.slow),
    );
  }
}
