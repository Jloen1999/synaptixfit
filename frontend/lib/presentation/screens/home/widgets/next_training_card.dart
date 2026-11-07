import 'package:flutter/material.dart';

import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../widgets/routine_day_labels.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Próximo día de entrenamiento con botón para empezar y CTA de check-in.
/// Misma información y jerarquía que la tarjeta de la pestaña Rutinas: foto
/// del ejercicio principal de fondo, cuándo toca, retraso y avance del ciclo.
class NextTrainingCard extends StatelessWidget {
  const NextTrainingCard({
    super.key,
    required this.day,
    required this.checkInDone,
    required this.onStart,
    required this.onCheckIn,
    this.onOpenRoutine,
    this.onRun,
    this.starting = false,
  });

  final HomeNextTrainingDay? day;
  final bool checkInDone;

  /// Empieza o reanuda la sesión del día (o crea una rutina si no hay).
  final VoidCallback onStart;
  final VoidCallback onCheckIn;

  /// Abre la rutina sin empezar (ver ejercicios antes).
  final VoidCallback? onOpenRoutine;

  /// «Empezar a correr» (ADR 0037): graba una carrera con el GPS.
  final VoidCallback? onRun;

  /// Creando la sesión: el botón muestra que está trabajando.
  final bool starting;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final next = day;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.homeTrainingTitle,
          actionLabel: onOpenRoutine == null
              ? null
              : l10n.homeTrainingSeeRoutine,
          onAction: onOpenRoutine,
        ),
        if (next == null)
          AppCard(
            child: AppEmptyState(
              icon: Icons.fitness_center_rounded,
              title: l10n.homeTrainingEmptyTitle,
              message: l10n.homeTrainingEmptyMessage,
              action: AppPrimaryButton(
                label: l10n.homeTrainingCreate,
                icon: Icons.add_rounded,
                onPressed: onStart,
              ),
            ),
          )
        else
          AppCoverCard(
            imageUrl: next.coverImageUrl,
            padding: const EdgeInsets.all(TokensSpacing.m),
            // Progreso y botones a todo el ancho, sin la foto detrás.
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (next.totalDays > 0) ...[
                  const SizedBox(height: TokensSpacing.s),
                  AppCycleProgress(
                    progress: next.cycleProgress,
                    label: l10n.trainingDaysProgress(
                      next.completedDays + next.skippedDays,
                      next.totalDays,
                    ),
                  ),
                ],
                const SizedBox(height: TokensSpacing.m),
                Wrap(
                  spacing: TokensSpacing.s,
                  runSpacing: TokensSpacing.s,
                  children: [
                    AppPrimaryButton(
                      label: next.inProgress
                          ? l10n.homeTrainingContinue
                          : l10n.homeTrainingStart,
                      icon: Icons.play_arrow_rounded,
                      loading: starting,
                      onPressed: onStart,
                    ),
                    if (!checkInDone)
                      AppSecondaryButton(
                        label: l10n.homeTrainingCheckIn,
                        icon: const Icon(Icons.fact_check_outlined),
                        onPressed: starting ? null : onCheckIn,
                      ),
                    if (onRun case final run?)
                      AppSecondaryButton(
                        label: l10n.homeStartRun,
                        icon: const Icon(Icons.directions_run_rounded),
                        onPressed: starting ? null : run,
                      ),
                  ],
                ),
                if (checkInDone) ...[
                  const SizedBox(height: TokensSpacing.s),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: TokensSize.iconXs,
                        color: context.palette.success,
                      ),
                      const SizedBox(width: TokensSpacing.xs),
                      Expanded(
                        child: Text(
                          l10n.homeTrainingCheckInDone,
                          style: context.textStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        next.routineName,
                        style: context.textStyles.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (next.inProgress)
                      AppCoverPill(
                        icon: Icons.play_circle_outline_rounded,
                        label: l10n.homeTrainingInProgress,
                        color: context.colors.primary,
                      ),
                  ],
                ),
                // «Miércoles 5 nov · Semana 2 de 4 · Tirón»: la misma regla
                // que la pestaña de Rutinas.
                Text(
                  nextDayHeadline(
                    l10n,
                    date: next.scheduledDate,
                    weekNumber: next.weekNumber,
                    totalWeeks: next.totalWeeks,
                    dayNumber: next.dayNumber,
                    dayName: next.dayName,
                  ),
                  style: context.textStyles.bodyLarge,
                ),
                if ((next.overdue && next.scheduledDate != null) ||
                    next.estimatedMinutes > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: TokensSpacing.xs),
                    child: Wrap(
                      spacing: TokensSpacing.xs,
                      runSpacing: TokensSpacing.xs,
                      children: [
                        if (next.overdue && next.scheduledDate != null)
                          AppCoverPill(
                            icon: Icons.schedule_rounded,
                            color: context.palette.warning,
                            label: overdueSinceLabel(l10n, next.scheduledDate!),
                          ),
                        // Duración prevista (la calcula el servidor).
                        if (next.estimatedMinutes > 0)
                          AppCoverPill(
                            icon: Icons.timer_outlined,
                            label: l10n.trainingEstimatedMinutes(
                              next.estimatedMinutes,
                            ),
                            semanticLabel: l10n.trainingEstimatedMinutesSpoken(
                              next.estimatedMinutes,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (next == null && (!checkInDone || onRun != null)) ...[
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.s,
            children: [
              if (!checkInDone)
                AppSecondaryButton(
                  label: l10n.homeTrainingCheckIn,
                  icon: const Icon(Icons.fact_check_outlined),
                  onPressed: onCheckIn,
                ),
              if (onRun case final run?)
                AppSecondaryButton(
                  label: l10n.homeStartRun,
                  icon: const Icon(Icons.directions_run_rounded),
                  onPressed: run,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
