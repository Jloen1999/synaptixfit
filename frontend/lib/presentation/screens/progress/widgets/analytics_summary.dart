import 'package:flutter/material.dart';

import '../../../../domain/models/progress/weekly_analytics.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'chart_card.dart';
import 'progress_labels.dart';

/// Totales del periodo: sesiones, minutos, calorías y RPE medio.
class AnalyticsSummary extends StatelessWidget {
  const AnalyticsSummary({super.key, required this.weekly});

  final WeeklyAnalytics weekly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final rpe = weekly.averageRpe;
    return MetricGrid(
      children: [
        AppMetricTile(
          icon: Icons.event_available_rounded,
          color: context.palette.sessions,
          value: ProgressFormat.integer(weekly.totalSessions),
          label: l10n.progressMetricSessions,
        ),
        AppMetricTile(
          icon: AppIcons.duration,
          color: context.colors.secondary,
          value: ProgressFormat.integer(weekly.totalMinutes),
          label: l10n.progressMetricMinutes,
        ),
        AppMetricTile(
          icon: Icons.local_fire_department_outlined,
          color: context.palette.calories,
          value: ProgressFormat.integer(weekly.totalCalories),
          label: l10n.progressMetricCalories,
        ),
        AppMetricTile(
          icon: Icons.speed_rounded,
          color: context.colors.tertiary,
          value: rpe == null
              ? l10n.progressNoValue
              : ProgressFormat.oneDecimal(rpe),
          label: l10n.progressMetricAverageRpe,
        ),
      ],
    );
  }
}

/// Acceso a la analítica con el resumen de las últimas 4 semanas.
class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({
    super.key,
    required this.weekly,
    required this.onOpen,
  });

  /// Nulo si no se pudo cargar.
  final WeeklyAnalytics? weekly;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final data = weekly;
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: context.colors.primary),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.progressAnalyticsTitle,
                      style: context.textStyles.titleMedium,
                    ),
                    Text(
                      l10n.progressAnalyticsLastWeeks(4),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: l10n.progressAnalyticsOpen,
                child: Icon(
                  AppIcons.next,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          if (data == null)
            InlineNotice(
              icon: Icons.cloud_off_rounded,
              message: l10n.progressSectionUnavailable,
            )
          else
            _CompactStats(weekly: data),
        ],
      ),
    );
  }
}

class _CompactStats extends StatelessWidget {
  const _CompactStats({required this.weekly});

  final WeeklyAnalytics weekly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final rpe = weekly.averageRpe;
    final items = [
      (
        ProgressFormat.integer(weekly.totalSessions),
        l10n.progressMetricSessions,
      ),
      (ProgressFormat.integer(weekly.totalMinutes), l10n.progressMetricMinutes),
      (
        ProgressFormat.integer(weekly.totalCalories),
        l10n.progressMetricCalories,
      ),
      (
        rpe == null ? l10n.progressNoValue : ProgressFormat.oneDecimal(rpe),
        l10n.progressMetricAverageRpe,
      ),
    ];
    return Row(
      children: [
        for (final (value, label) in items)
          Expanded(
            child: Column(
              children: [
                Text(value, style: context.textStyles.titleLarge),
                Text(
                  label,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
