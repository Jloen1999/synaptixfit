import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../progress/widgets/chart_card.dart';
import '../../../progress/widgets/chart_style.dart';
import '../../../progress/widgets/progress_labels.dart';
import '../bloc/exercise_progress_bloc.dart';

/// «Tu evolución» en la ficha de un ejercicio: el peso máximo estimado por día
/// en una gráfica, explicado en una frase. Sin datos con peso, explica cómo
/// conseguirlos.
class ExerciseProgressSection extends StatelessWidget {
  const ExerciseProgressSection({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ExerciseProgressBloc>()
            ..add(ExerciseProgressRequested(exerciseId)),
      child: BlocBuilder<ExerciseProgressBloc, ExerciseProgressState>(
        builder: (context, state) => _ProgressCard(
          state: state,
          onRetry: () => context.read<ExerciseProgressBloc>().add(
            ExerciseProgressRequested(exerciseId),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state, required this.onRetry});

  final ExerciseProgressState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final points = state.points;
    final best = state.best;
    final color = context.colors.secondary;
    const kg = ProgressFormat.oneDecimal;
    return ChartCard(
      title: l10n.trainingProgressTitle,
      subtitle: l10n.trainingProgressExplain,
      semanticsSummary: points.isEmpty
          ? null
          : l10n.trainingProgressSemantics(
              kg(points.first.estimatedMaxKg),
              kg(points.last.estimatedMaxKg),
              points.length,
            ),
      footer: best == null
          ? null
          : Wrap(
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.xs,
              children: [
                AppPill(
                  icon: Icons.emoji_events_outlined,
                  label: l10n.trainingProgressBest(kg(best.estimatedMaxKg)),
                  color: color,
                ),
                AppPill(
                  icon: Icons.history_rounded,
                  label: l10n.trainingProgressLast(
                    kg(points.last.weightKg),
                    points.last.reps,
                  ),
                ),
                if (state.change > 0)
                  AppPill(
                    icon: Icons.trending_up_rounded,
                    label: l10n.trainingProgressUp(kg(state.change)),
                    color: context.colors.tertiary,
                  ),
              ],
            ),
      child: switch (state.status) {
        ExerciseProgressStatus.loading => const AppSkeletonGroup(
          child: AppSkeleton(height: TokensSize.chartCompact),
        ),
        ExerciseProgressStatus.failure => AppErrorView(
          error: state.error!,
          onRetry: onRetry,
        ),
        ExerciseProgressStatus.ready when points.isEmpty => InlineNotice(
          icon: Icons.show_chart_rounded,
          message: l10n.trainingProgressEmpty,
        ),
        ExerciseProgressStatus.ready => SizedBox(
          height: TokensSize.chartCompact,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: points.length <= 1 ? 1 : (points.length - 1).toDouble(),
              borderData: FlBorderData(show: false),
              gridData: ChartStyle.grid(context),
              titlesData: ChartStyle.titles(
                context,
                bottom: (i) => i >= 0 && i < points.length
                    ? DateFormat.MMMd().format(points[i].date)
                    : null,
                count: points.length,
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => context.colors.inverseSurface,
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        l10n.trainingProgressTooltip(
                          kg(s.y),
                          kg(points[s.x.round()].weightKg),
                          points[s.x.round()].reps,
                        ),
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
                      FlSpot(i.toDouble(), points[i].estimatedMaxKg),
                  ],
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: color,
                  barWidth: TokensSize.chartLine,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
            duration: ChartStyle.duration(context),
          ),
        ),
      },
    );
  }
}
