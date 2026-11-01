import 'package:flutter/material.dart';

import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/models/training/routine.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'training_labels.dart';

/// Tarjeta de rutina para listados (propias o de la comunidad), con la foto
/// del ejercicio que la representa de fondo ([AppCoverCard]).
///
/// Delante, lo que hace falta para actuar: el nombre grande, si está en curso
/// cuándo toca el próximo día ([nextDay]) y si va con retraso, y el avance del
/// ciclo. Lo secundario (semanas, ejercicios, objetivo) va en pastillas debajo.
class RoutineSummaryCard extends StatelessWidget {
  const RoutineSummaryCard({
    super.key,
    required this.routine,
    required this.onTap,
    this.showAuthor = false,
    this.trailing,
    this.nextDay,
  });

  final RoutineSummary routine;
  final VoidCallback onTap;
  final bool showAuthor;
  final Widget? trailing;

  /// Próximo día si esta es la rutina en curso (lo calcula el servidor).
  final PendingDay? nextDay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final r = routine;
    final next = nextDay;
    final active = r.status == RoutineStatus.active;
    return AppCoverCard(
      onTap: onTap,
      imageUrl: r.coverImageUrl,
      padding: const EdgeInsets.all(TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!showAuthor)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: TokensSpacing.xs,
                        ),
                        child: AppCoverPill(
                          icon: r.status.icon,
                          label: r.status.label(l10n),
                          color: active
                              ? context.colors.primary
                              : context.colors.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      r.name,
                      style: context.textStyles.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showAuthor && r.authorName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: TokensSpacing.xxs),
                        child: Row(
                          children: [
                            AppAvatar(
                              name: r.authorName!,
                              radius: TokensSize.iconS / 2,
                            ),
                            const SizedBox(width: TokensSpacing.xs),
                            Flexible(
                              child: Text(
                                l10n.trainingByAuthor(r.authorName!),
                                style: context.textStyles.labelMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (next != null && next.routineId == r.id) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(
              nextDayHeadline(
                l10n,
                date: next.scheduledDate,
                weekNumber: next.weekNumber,
                totalWeeks: next.totalWeeks,
                dayNumber: next.dayNumber,
                dayName: next.dayName,
              ),
              style: context.textStyles.bodyMedium,
            ),
            if (next.overdue && next.scheduledDate != null)
              Padding(
                padding: const EdgeInsets.only(top: TokensSpacing.xxs),
                child: AppCoverPill(
                  icon: Icons.schedule_rounded,
                  color: context.palette.warning,
                  label: overdueSinceLabel(l10n, next.scheduledDate!),
                ),
              ),
          ] else if (r.description != null &&
              r.description!.trim().isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(
              r.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          if (!showAuthor && r.totalDays > 0) ...[
            const SizedBox(height: TokensSpacing.s),
            AppCycleProgress(
              progress: r.progress,
              label: l10n.trainingDaysProgress(
                r.completedDays + r.skippedDays,
                r.totalDays,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.xs,
            runSpacing: TokensSpacing.xs,
            children: [
              AppCoverPill(
                icon: Icons.calendar_view_week_rounded,
                label: l10n.trainingWeeksCount(r.durationWeeks),
              ),
              AppCoverPill(
                icon: Icons.fitness_center_rounded,
                label: l10n.trainingExercisesCount(r.exerciseCount),
              ),
              if (r.goal != null)
                AppCoverPill(icon: Icons.flag_outlined, label: r.goal!.label(l10n)),
            ],
          ),
        ],
      ),
    );
  }
}
