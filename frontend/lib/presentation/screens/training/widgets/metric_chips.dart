import 'package:flutter/material.dart';

import '../../../../domain/models/training/routine.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'training_labels.dart';

/// Chips semánticos de los parámetros de un ejercicio: series × repeticiones,
/// descanso, peso, duración, distancia y calorías estimadas (MET).
class ExerciseParameterChips extends StatelessWidget {
  const ExerciseParameterChips({
    super.key,
    required this.parameters,
    this.met,
    this.bodyWeightKg,
    this.realDurationSeconds,
  });

  final ExerciseParameters parameters;
  final double? met;
  final double? bodyWeightKg;
  final int? realDurationSeconds;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final p = parameters;
    final weights = p.weightsKg;
    final weightLabel = weights != null && weights.isNotEmpty
        ? weights.map(formatNumber).join('/')
        : p.weightKg != null && p.weightKg! > 0
        ? formatNumber(p.weightKg!)
        : null;
    final distance = p.distanceMeters;
    final metValue = met;
    return Wrap(
      spacing: TokensSpacing.xs,
      runSpacing: TokensSpacing.xs,
      children: [
        AppPill(
          icon: Icons.repeat_rounded,
          color: context.colors.secondary,
          label: p.isometricSeconds != null
              ? l10n.trainingChipSetsSeconds(p.sets, p.isometricSeconds!)
              : l10n.trainingChipSetsReps(p.sets, p.reps),
        ),
        AppPill(
          icon: Icons.hourglass_bottom_rounded,
          label: l10n.trainingChipRest(p.restSeconds),
        ),
        if (weightLabel != null)
          AppPill(
            icon: Icons.fitness_center_rounded,
            label: l10n.trainingChipWeight(weightLabel),
          ),
        if (p.targetDurationSeconds != null)
          AppPill(
            icon: Icons.timer_outlined,
            label: formatClock(p.targetDurationSeconds!),
            semanticLabel: l10n.trainingChipDurationSemantics(
              formatClock(p.targetDurationSeconds!),
            ),
          ),
        if (distance != null)
          AppPill(
            icon: Icons.straighten_rounded,
            label: distance >= 1000
                ? l10n.trainingChipDistanceKm(formatNumber(distance / 1000))
                : l10n.trainingChipDistanceM(distance),
          ),
        if (realDurationSeconds != null && realDurationSeconds! > 0)
          AppPill(
            icon: Icons.check_circle_outline_rounded,
            color: context.palette.success,
            label: l10n.trainingChipRealDuration(
              formatClock(realDurationSeconds!),
            ),
          ),
        if (metValue != null && metValue > 0)
          AppPill(
            icon: Icons.local_fire_department_rounded,
            color: context.palette.calories,
            label: l10n.trainingChipKcal(
              p
                  .estimatedCalories(met: metValue, bodyWeightKg: bodyWeightKg)
                  .round(),
            ),
          ),
      ],
    );
  }
}
