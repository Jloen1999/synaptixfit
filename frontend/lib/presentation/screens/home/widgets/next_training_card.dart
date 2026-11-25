import 'package:flutter/material.dart';

import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../widgets/routine_day_labels.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Próximo día de entrenamiento con «Empezar» (1 toque) y el registro diario.
/// Misma información que la tarjeta de Entreno › Gimnasio: foto del ejercicio
/// principal de fondo con el texto abajo (ADR 0042), cuándo toca, retraso y
/// avance del ciclo. «Empezar» tiene el mismo peso que el de «Tu día»: relleno
/// si «Tu día» no lleva el botón relleno de la pantalla ([startPrimary]) y
/// tonal si lo lleva; «¿Qué tal estás hoy?» va con borde. Grabar una carrera
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
    this.startPrimary = false,
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

  /// «Empezar» es el botón relleno de Inicio (ninguna otra tarjeta lo lleva:
  /// un solo relleno por pantalla); si no, tonal.
  final bool startPrimary;

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
              icon: AppIcons.routine,
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
                      _StartButton(
                        label: next.inProgress
                            ? l10n.homeTrainingContinue
                            : l10n.homeTrainingStart,
                        primary: startPrimary,
                        loading: starting,
                        onPressed: onStart,
                      ),
                    if (!checkInDone)
                      AppSecondaryButton(
                        label: l10n.homeTrainingCheckIn,
                        icon: const Icon(AppIcons.checkIn),
                        onPressed: starting ? null : onCheckIn,
                      ),
                  ],
                ),
                if (checkInDone) ...[
                  const SizedBox(height: TokensSpacing.s),
                  Row(
                    children: [
                      Icon(
                        AppIcons.done,
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
              icon: const Icon(AppIcons.checkIn),
              onPressed: onCheckIn,
            ),
          ),
        ],
      ],
    );
  }
}

/// «Empezar» del próximo entreno: relleno (el destacado de Inicio) o tonal,
/// nunca con borde, para pesar lo mismo que «Empezar» de «Tu día».
class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.label,
    required this.primary,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool primary;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return AppPrimaryButton(
        label: label,
        icon: AppIcons.start,
        loading: loading,
        onPressed: onPressed,
      );
    }
    if (loading) {
      // Como los demás botones: la carga se anuncia aunque el botón,
      // deshabilitado, pierda el foco.
      return FilledButton.tonal(
        onPressed: null,
        child: Semantics(
          liveRegion: true,
          label: '$label, ${context.localizations.commonLoading}',
          child: const ExcludeSemantics(
            child: SizedBox.square(
              dimension: TokensSize.iconS,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: const Icon(AppIcons.start),
      label: Text(label),
    );
  }
}
