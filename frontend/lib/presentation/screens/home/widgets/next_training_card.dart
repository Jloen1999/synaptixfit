import 'package:flutter/material.dart';

import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Próximo día de entrenamiento con botón para empezar y CTA de check-in.
class NextTrainingCard extends StatelessWidget {
  const NextTrainingCard({
    super.key,
    required this.day,
    required this.checkInDone,
    required this.onStart,
    required this.onCheckIn,
    this.onOpenRoutine,
    this.starting = false,
  });

  final HomeNextTrainingDay? day;
  final bool checkInDone;

  /// Empieza o reanuda la sesión del día (o crea una rutina si no hay).
  final VoidCallback onStart;
  final VoidCallback onCheckIn;

  /// Abre la rutina sin empezar (ver ejercicios antes).
  final VoidCallback? onOpenRoutine;

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
        AppCard(
          child: next == null
              ? AppEmptyState(
                  icon: Icons.fitness_center_rounded,
                  title: l10n.homeTrainingEmptyTitle,
                  message: l10n.homeTrainingEmptyMessage,
                  action: AppPrimaryButton(
                    label: l10n.homeTrainingCreate,
                    icon: Icons.add_rounded,
                    onPressed: onStart,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(TokensSpacing.s),
                          decoration: BoxDecoration(
                            color: context.colors.secondaryContainer,
                            borderRadius: BorderRadius.circular(TokensRadius.m),
                          ),
                          child: Icon(
                            Icons.fitness_center_rounded,
                            color: context.colors.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: TokensSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                next.routineName,
                                style: context.textStyles.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                [
                                  l10n.homeTrainingWeekDay(
                                    next.weekNumber,
                                    next.dayNumber,
                                  ),
                                  ?next.dayName,
                                ].join(' · '),
                                style: context.textStyles.bodyMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (next.inProgress)
                          AppPill(
                            icon: Icons.play_circle_outline_rounded,
                            label: l10n.homeTrainingInProgress,
                            color: context.colors.primary,
                          ),
                      ],
                    ),
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
                          Text(
                            l10n.homeTrainingCheckInDone,
                            style: context.textStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
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
