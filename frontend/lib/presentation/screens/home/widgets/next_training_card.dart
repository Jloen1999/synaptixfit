import 'package:flutter/material.dart';

import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../widgets/routine_day_labels.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Próximo día de entrenamiento con «Empezar» (1 toque) y el registro diario.
/// Misma información que la tarjeta de Entreno › Gimnasio: foto del ejercicio
/// principal de fondo con el texto abajo (ADR 0042), cuándo toca, retraso y
/// avance del ciclo. Sus botones son
/// secundarios: el destacado de Inicio es el de «Tu día». Grabar una carrera
/// vive en Entreno › Correr (ADR 0038).
class NextTrainingCard extends StatelessWidget {
  const NextTrainingCard({
    super.key,
    required this.day,
    required this.checkInDone,
    required this.onStart,
    required this.onCheckIn,
    this.onOpenRoutine,
    this.starting = false,
    this.showStart = true,
  });

  final HomeNextTrainingDay? day;
  final bool checkInDone;

  /// Empieza o reanuda la sesión del día (o crea una rutina si no hay).
  final VoidCallback onStart;
  final VoidCallback onCheckIn;

  /// Abre la rutina sin empezar (ver ejercicios antes).
  final VoidCallback? onOpenRoutine;

  /// `false` si «Tu día» ya ofrece «Empezar» (un camino por destino).
  final bool showStart;

  /// Creando la sesión: el botón muestra que está trabajando.
  final bool starting;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final next = day;
    final whenText = next == null
        ? ''
        : [
            if (next.scheduledDate != null)
              scheduledDayLabel(l10n, next.scheduledDate!)
            else
              weekdayName(l10n, next.dayNumber),
            if (next.dayName?.trim() case final name? when name.isNotEmpty)
              name,
          ].join(' · ');
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
              action: AppSecondaryButton(
                label: l10n.homeTrainingCreate,
                icon: const Icon(AppIcons.add),
                onPressed: onStart,
              ),
            ),
          )
        else
          AppCoverCard(
            layout: AppCoverLayout.bottom,
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
                    if (showStart)
                      AppSecondaryButton(
                        label: next.inProgress
                            ? l10n.homeTrainingContinue
                            : l10n.homeTrainingStart,
                        icon: const Icon(Icons.play_arrow_rounded),
                        loading: starting,
                        onPressed: onStart,
                      ),
                    if (!checkInDone)
                      AppSecondaryButton(
                        label: l10n.homeTrainingCheckIn,
                        icon: const Icon(Icons.fact_check_outlined),
                        onPressed: starting ? null : onCheckIn,
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
            // Texto abajo sobre la foto (ADR 0042): el estado en pastilla
            // sólida y tres datos como mucho (qué rutina, cuándo y cuánto).
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (next.inProgress ||
                    (next.overdue && next.scheduledDate != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
                    child: next.inProgress
                        ? AppCoverPill(
                            icon: AppIcons.inProgress,
                            label: l10n.homeTrainingInProgress,
                            color: context.colors.primary,
                          )
                        : AppCoverPill(
                            icon: AppIcons.overdue,
                            color: context.palette.warning,
                            label: overdueSinceLabel(l10n, next.scheduledDate!),
                          ),
                  ),
                Text(
                  next.routineName,
                  style: context.textStyles.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // «Miércoles 5 nov · Tirón · 45 min»: cuándo, qué día y la
                // duración que calcula el servidor (la semana va en el pie).
                Semantics(
                  label: [
                    whenText,
                    if (next.estimatedMinutes > 0)
                      l10n.trainingEstimatedMinutesSpoken(
                        next.estimatedMinutes,
                      ),
                  ].join(', '),
                  excludeSemantics: true,
                  child: Text(
                    [
                      whenText,
                      if (next.estimatedMinutes > 0)
                        l10n.trainingEstimatedMinutes(next.estimatedMinutes),
                    ].join(' · '),
                    style: context.textStyles.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        if (next == null && !checkInDone) ...[
          const SizedBox(height: TokensSpacing.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppSecondaryButton(
              label: l10n.homeTrainingCheckIn,
              icon: const Icon(Icons.fact_check_outlined),
              onPressed: onCheckIn,
            ),
          ),
        ],
      ],
    );
  }
}
