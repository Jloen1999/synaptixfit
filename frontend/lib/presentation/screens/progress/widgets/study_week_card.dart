import 'package:flutter/material.dart';

import '../../../../domain/models/progress/study_week.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'chart_card.dart';

/// «Tu estudio»: cómo va la semana académica (concentración, bloques de estudio
/// hechos, repasos y aciertos en simulacros). Es el equivalente del resumen de
/// entrenamiento para quien estudia.
class StudyWeekCard extends StatelessWidget {
  const StudyWeekCard({
    super.key,
    required this.week,
    required this.onFocus,
    required this.onReview,
    required this.onRetry,
  });

  /// Nulo si no se pudo cargar.
  final StudyWeek? week;

  /// Abre el Pomodoro (acción del estado vacío).
  final VoidCallback onFocus;

  /// Lleva a los repasos pendientes.
  final VoidCallback onReview;

  /// Vuelve a cargar Progreso tras un error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final data = week;
    if (data == null) {
      return ChartCard(
        title: l10n.progressStudyTitle,
        subtitle: l10n.progressStudySubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InlineNotice(
              icon: Icons.cloud_off_rounded,
              message: l10n.progressSectionUnavailable,
            ),
            const SizedBox(height: TokensSpacing.s),
            AppSecondaryButton(
              label: l10n.commonRetry,
              icon: const Icon(AppIcons.refresh),
              onPressed: onRetry,
            ),
          ],
        ),
      );
    }
    if (data.empty) {
      return ChartCard(
        title: l10n.progressStudyTitle,
        subtitle: l10n.progressStudySubtitle,
        child: AppEmptyState.compact(
          icon: Icons.menu_book_rounded,
          title: l10n.progressStudyEmpty,
          action: AppSecondaryButton(
            label: l10n.progressStudyFocus,
            icon: const Icon(AppIcons.focusTimer),
            onPressed: onFocus,
          ),
        ),
      );
    }
    // Un solo color (el de la mente): es una tarjeta de estudio.
    final study = context.palette.study;
    return ChartCard(
      title: l10n.progressStudyTitle,
      subtitle: l10n.progressStudySubtitle,
      footer: data.reviewsDue > 0
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.replay_rounded),
                label: Text(l10n.progressStudyReviewNow(data.reviewsDue)),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.weeklyGoalHours > 0) ...[
            _GoalProgress(
              hours: data.studyHours,
              goal: data.weeklyGoalHours,
              color: study,
            ),
            const SizedBox(height: TokensSpacing.m),
          ],
          AppTileGrid(
            minTileWidth: TokensLayout.minTouchTarget * 3,
            children: [
              AppMetricTile(
                bare: true,
                icon: AppIcons.focusTimer,
                color: study,
                value: l10n.progressStudyMinutes(data.focusMinutes),
                label: l10n.progressStudyFocusLabel,
              ),
              AppMetricTile(
                bare: true,
                icon: Icons.event_available_rounded,
                color: study,
                value: data.studyBlocksPlanned == 0
                    ? l10n.progressStudyNoPlan
                    : l10n.progressStudyBlocksDone(
                        data.studyBlocksCompleted,
                        data.studyBlocksPlanned,
                      ),
                label: l10n.progressStudyBlocksLabel,
                detail: data.planAdherence == null
                    ? null
                    : l10n.progressStudyAdherence(data.planAdherence!),
              ),
              AppMetricTile(
                bare: true,
                icon: Icons.replay_rounded,
                color: study,
                value: '${data.reviewsCompleted}',
                label: l10n.progressStudyReviewsLabel,
              ),
              if (data.testsCompleted > 0)
                AppMetricTile(
                  bare: true,
                  icon: Icons.quiz_outlined,
                  color: study,
                  value: l10n.progressStudyScore(data.averageTestScore ?? 0),
                  label: l10n.progressStudyTestsLabel(data.testsCompleted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horas de estudio de la semana frente al objetivo del perfil académico.
class _GoalProgress extends StatelessWidget {
  const _GoalProgress({
    required this.hours,
    required this.goal,
    required this.color,
  });

  final int hours;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final reached = hours >= goal;
    final semantics = l10n.progressStudyGoalSemantics(hours, goal);
    return Semantics(
      label: reached
          ? '$semantics. ${l10n.progressStudyGoalReached}'
          : semantics,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.progressStudyGoal(hours, goal),
                  style: context.textStyles.titleSmall,
                ),
              ),
              if (reached) ...[
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: TokensSize.iconS,
                ),
                const SizedBox(width: TokensSpacing.xs),
                Text(
                  l10n.progressStudyGoalReached,
                  style: context.textStyles.labelLarge,
                ),
              ],
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          LinearProgressIndicator(
            value: (hours / goal).clamp(0.0, 1.0),
            color: color,
          ),
        ],
      ),
    );
  }
}
