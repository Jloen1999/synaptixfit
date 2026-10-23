import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/models/admin/admin_user_stats.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/admin_widgets.dart';
import '../bloc/admin_user_detail_bloc.dart';

/// Sub-pestaña Estadísticas: cifras acumuladas y actividad semanal.
class AdminUserStatsTab extends StatelessWidget {
  const AdminUserStatsTab({super.key, required this.state});

  final AdminUserDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final stats = state.stats;
    if (stats == null) {
      return state.statsError != null
          ? AppErrorView(
              error: state.statsError!,
              onRetry: () => context.read<AdminUserDetailBloc>().add(
                const AdminUserDetailEvent.refreshed(),
              ),
            )
          : AppEmptyState(
              icon: Icons.query_stats_rounded,
              title: l10n.adminStatsEmpty,
            );
    }
    final colors = context.colors;
    final palette = context.palette;
    const n = AdminFormat.number;
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        AdminContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.adminStatsLastActivity(
                  AdminFormat.dateTime(stats.lastActivityAt),
                ),
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              _StatsGroup(
                title: l10n.adminStatsTraining,
                color: colors.secondary,
                icon: Icons.fitness_center_rounded,
                items: [
                  (l10n.adminStatsSessions, n(stats.trainingSessions)),
                  (l10n.adminStatsMinutes, n(stats.trainingMinutes)),
                  (l10n.adminStatsCalories, n(stats.caloriesBurned)),
                  (
                    l10n.adminStatsAverageRpe,
                    AdminFormat.decimal(stats.averageRpe),
                  ),
                  (
                    l10n.adminStatsRoutines,
                    l10n.adminStatsOfTotal(
                      n(stats.activeRoutines),
                      n(stats.routines),
                    ),
                  ),
                ],
              ),
              _StatsGroup(
                title: l10n.adminStatsStudy,
                color: colors.tertiary,
                icon: Icons.school_rounded,
                items: [
                  (l10n.adminStatsStudyBlocks, n(stats.completedStudyBlocks)),
                  (l10n.adminStatsStudyMinutes, n(stats.studyMinutes)),
                  (l10n.adminStatsFocusSessions, n(stats.focusSessions)),
                  (l10n.adminStatsFocusMinutes, n(stats.focusMinutes)),
                  (l10n.adminStatsDeadlinesDone, n(stats.completedDeadlines)),
                  (l10n.adminStatsDeadlinesPending, n(stats.pendingDeadlines)),
                  (
                    l10n.adminStatsAdherence,
                    l10n.adminStatsAdherenceValue(
                      stats.academicAdherencePercent,
                      stats.adherenceWeeks,
                    ),
                  ),
                  (l10n.adminStatsSubjects, n(stats.subjects)),
                  (l10n.adminStatsNotes, n(stats.notes)),
                  (l10n.adminStatsFiles, n(stats.files)),
                ],
              ),
              _StatsGroup(
                title: l10n.adminStatsAchievements,
                color: palette.accent,
                icon: Icons.emoji_events_rounded,
                items: [
                  (
                    l10n.adminStatsChallenges,
                    l10n.adminStatsOfTotal(
                      n(stats.completedChallenges),
                      n(stats.challenges),
                    ),
                  ),
                  (l10n.adminStatsBadges, n(stats.badges)),
                  (l10n.adminStatsPosts, n(stats.posts)),
                  (l10n.adminStatsComments, n(stats.comments)),
                  (l10n.adminStatsFriends, n(stats.friends)),
                ],
              ),
              const SizedBox(height: TokensSpacing.s),
              _WeeklyChartCard(activity: state.activity),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGroup extends StatelessWidget {
  const _StatsGroup({
    required this.title,
    required this.color,
    required this.icon,
    required this.items,
  });

  final String title;
  final Color color;
  final IconData icon;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: TokensSpacing.s),
                Text(title, style: context.textStyles.titleMedium),
              ],
            ),
            const SizedBox(height: TokensSpacing.s),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = math.max(
                  2,
                  (constraints.maxWidth / 180).floor(),
                );
                const gap = TokensSpacing.s;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final (label, value) in items)
                      SizedBox(
                        width: width,
                        child: _StatCell(
                          label: label,
                          value: value,
                          color: color,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TokensSpacing.s),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(TokensRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: context.textStyles.titleMedium),
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.activity});

  final List<AdminWeeklyActivity> activity;

  static int _training(AdminWeeklyActivity w) => w.trainingMinutes;

  static int _study(AdminWeeklyActivity w) => w.studyMinutes + w.focusMinutes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    final training = colors.secondary;
    final study = colors.tertiary;
    final labelStyle = context.textStyles.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final maxY = activity
        .expand((w) => [_training(w), _study(w)])
        .fold<int>(0, math.max);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminStatsWeeklyTitle,
            style: context.textStyles.titleMedium,
          ),
          const SizedBox(height: TokensSpacing.xs),
          Wrap(
            spacing: TokensSpacing.m,
            children: [
              _Legend(color: training, label: l10n.adminStatsWeeklyTraining),
              _Legend(
                color: study,
                label: l10n.adminStatsWeeklyStudy,
                outlined: true,
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          SizedBox(
            height: 220,
            child: activity.isEmpty
                ? Center(child: Text(l10n.adminStatsWeeklyEmpty))
                : AppChartSummary(
                    summary: _summary(context),
                    child: BarChart(
                      BarChartData(
                        maxY: (maxY == 0 ? 1 : maxY * 1.15).toDouble(),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: colors.outlineVariant,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: labelStyle,
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= activity.length || i.isOdd) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    top: TokensSpacing.xs,
                                  ),
                                  child: Text(
                                    AdminFormat.shortDate(
                                      activity[i].weekStart,
                                    ),
                                    style: labelStyle,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < activity.length; i++)
                            BarChartGroupData(
                              x: i,
                              barsSpace: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: _training(activity[i]).toDouble(),
                                  color: training,
                                  width: 6,
                                ),
                                // Estudio: relleno claro con borde, para
                                // distinguirlo del entrenamiento sin el color.
                                BarChartRodData(
                                  toY: _study(activity[i]).toDouble(),
                                  color: study.withValues(alpha: 0.3),
                                  borderSide: BorderSide(color: study),
                                  width: 6,
                                ),
                              ],
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

  /// Periodo y, por cada serie, última semana, mejor semana y media semanal.
  String _summary(BuildContext context) {
    final l10n = context.localizations;
    String series(String label, int Function(AdminWeeklyActivity) value) {
      final values = activity.map(value).toList();
      final total = values.fold<int>(0, (a, b) => a + b);
      return l10n.adminStatsWeeklySeriesSummary(
        label,
        AdminFormat.number(values.last),
        AdminFormat.number(values.fold<int>(0, math.max)),
        AdminFormat.decimal(total / values.length),
      );
    }

    return l10n.adminStatsWeeklySemantics(
      activity.length,
      AdminFormat.shortDate(activity.first.weekStart),
      AdminFormat.shortDate(activity.last.weekStart),
      [
        series(l10n.adminStatsWeeklyTraining, _training),
        series(l10n.adminStatsWeeklyStudy, _study),
      ].join('; '),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;

  /// Igual que las barras: relleno claro con borde en lugar de relleno sólido.
  final bool outlined;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: outlined ? color.withValues(alpha: 0.3) : color,
          border: outlined ? Border.all(color: color) : null,
          borderRadius: BorderRadius.circular(TokensRadius.s / 4),
        ),
      ),
      const SizedBox(width: TokensSpacing.xs),
      Text(label, style: context.textStyles.labelMedium),
    ],
  );
}
