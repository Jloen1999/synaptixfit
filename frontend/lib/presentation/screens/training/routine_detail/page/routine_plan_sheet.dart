import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/training_labels.dart';

/// «Tu plan, semana a semana»: qué toca cada semana en palabras sencillas
/// (Base, Subir, Semana suave…), sus fechas, dónde está la persona y qué
/// conviene hacer al terminar (ADR 0032).
Future<void> showRoutinePlanSheet(BuildContext context, Routine routine) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PlanSheet(routine: routine),
  );
}

class _PlanSheet extends StatelessWidget {
  const _PlanSheet({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final next = routine.nextStep;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.l,
          0,
          TokensSpacing.l,
          TokensSpacing.l,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.trainingPlanSheetTitle,
              style: context.textStyles.titleLarge,
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.trainingPlanSheetIntro,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
          for (final week in routine.weeks)
            _WeekRow(
              week: week,
              current:
                  week.number == routine.currentWeek &&
                  week.status != ProgressStatus.completed,
            ),
          if (next != null) ...[
            const SizedBox(height: TokensSpacing.m),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, color: context.colors.tertiary),
                      const SizedBox(width: TokensSpacing.s),
                      Text(
                        l10n.trainingPlanAfterTitle,
                        style: context.textStyles.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensSpacing.xs),
                  Text(switch (next) {
                    RoutineNextStep.repeatStronger =>
                      l10n.trainingPlanNextRepeat,
                    RoutineNextStep.newPlan => l10n.trainingPlanNextNew,
                  }),
                  if (next == RoutineNextStep.newPlan) ...[
                    const SizedBox(height: TokensSpacing.s),
                    AppSecondaryButton(
                      label: l10n.trainingPlanSeeTemplates,
                      icon: const Icon(Icons.view_list_rounded),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(TrainingPaths.templates);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.week, required this.current});

  final RoutineWeek week;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final done = week.status == ProgressStatus.completed;
    final range = weekRange(l10n, week.startsOn, week.endsOn);
    final type = week.type;
    return Container(
      margin: const EdgeInsets.only(bottom: TokensSpacing.s),
      padding: const EdgeInsets.all(TokensSpacing.m),
      decoration: BoxDecoration(
        color: current
            ? context.colors.secondaryContainer
            : context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(TokensRadius.m),
        border: current
            ? Border.all(
                color: context.colors.secondary,
                width: TokensSize.focusRing,
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : current
                ? Icons.my_location_rounded
                : Icons.radio_button_unchecked_rounded,
            color: done || current
                ? context.colors.secondary
                : context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    weekTitle(l10n, week.number, week.name),
                    if (type != null) type.label(l10n),
                  ].join(' · '),
                  style: context.textStyles.titleSmall,
                ),
                if (range != null)
                  Text(
                    range,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                if (type != null)
                  Text(
                    type.description(l10n),
                    style: context.textStyles.bodySmall,
                  ),
                if (current || done)
                  Padding(
                    padding: const EdgeInsets.only(top: TokensSpacing.xs),
                    child: AppPill(
                      icon: done
                          ? Icons.check_rounded
                          : Icons.my_location_rounded,
                      label: done
                          ? l10n.trainingPlanWeekDone
                          : l10n.trainingPlanYouAreHere,
                      color: context.colors.secondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
