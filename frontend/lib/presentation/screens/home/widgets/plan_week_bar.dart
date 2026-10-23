import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// «Tu semana»: bloques planificados frente a completados por día y, en una
/// línea, lo hecho en la semana (sesiones, estudio y kcal).
class PlanWeekBar extends StatelessWidget {
  const PlanWeekBar({
    super.key,
    required this.days,
    required this.week,
    this.focus = UsageFocus.both,
    required this.onOpenPlanner,
    this.now,
  });

  final List<HomePlanDay> days;
  final HomeWeekKpis week;

  /// Enfoque de uso: el resumen solo nombra lo que la persona hace.
  final UsageFocus focus;
  final VoidCallback onOpenPlanner;
  final DateTime? now;

  static const _barHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final planned = days.fold<int>(0, (sum, d) => sum + d.planned);
    final completed = days.fold<int>(0, (sum, d) => sum + d.completed);
    final maxValue = days.fold<int>(
      1,
      (m, d) => math.max(m, math.max(d.planned, d.completed)),
    );
    final current = now ?? DateTime.now();
    const weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final longDay = DateFormat.EEEE('es');
    final number = NumberFormat.decimalPattern('es');
    final weekParts = [
      if (focus.includesFitness)
        week.plannedSessions != null && week.plannedSessions! > 0
            ? l10n.homeWeekSessionsOfPlanned(
                week.sessions,
                week.plannedSessions!,
              )
            : l10n.homeWeekSessions(week.sessions),
      if (focus.includesAcademic)
        l10n.homeWeekStudyMinutes(week.studyMinutesCompleted),
      if (focus.includesFitness)
        l10n.homeWeekCalories(number.format(week.trainingCalories.round())),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sin enlace propio: el calendario ya se abre desde la agenda.
        AppSectionHeader(title: l10n.homePlanWeekTitle),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                planned == 0
                    ? l10n.homePlanWeekEmpty
                    : l10n.homePlanWeekSummary(completed, planned),
                style: context.textStyles.labelLarge,
              ),
              Text(
                weekParts.join(' · '),
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: Semantics(
                        label: l10n.homePlanDaySemantics(
                          longDay.format(day.date),
                          day.completed,
                          day.planned,
                        ),
                        excludeSemantics: true,
                        child: _DayColumn(
                          day: day,
                          maxValue: maxValue,
                          height: _barHeight,
                          label: l10n.commonWeekdayInitial(
                            weekdays[day.date.weekday - 1],
                          ),
                          isToday: DateUtils.isSameDay(day.date, current),
                          fill: focus == UsageFocus.fitness
                              ? context.palette.sessions
                              : context.palette.study,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.maxValue,
    required this.height,
    required this.label,
    required this.isToday,
    required this.fill,
  });

  final HomePlanDay day;
  final int maxValue;
  final double height;
  final String label;
  final bool isToday;

  /// Color de lo completado (el del ámbito: estudio o entrenamiento).
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final plannedHeight = height * day.planned / maxValue;
    final completedHeight =
        height * math.min(day.completed, maxValue) / maxValue;
    final done = day.planned > 0 && day.completed >= day.planned;
    final completedColor = done ? context.palette.success : fill;
    return Column(
      children: [
        SizedBox(
          height: height,
          width: TokensSize.iconS,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: math.max(plannedHeight, TokensSpacing.xs),
                decoration: BoxDecoration(
                  // outline: la barra de lo planificado llega a 3:1 con la tarjeta.
                  color: context.colors.outline,
                  borderRadius: BorderRadius.circular(TokensRadius.s),
                ),
              ),
              if (day.completed > 0)
                Container(
                  height: completedHeight,
                  decoration: BoxDecoration(
                    color: completedColor,
                    borderRadius: BorderRadius.circular(TokensRadius.s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: TokensSpacing.xs),
        Text(
          label.toUpperCase(),
          style:
              (isToday
                      ? context.textStyles.labelLarge?.copyWith(
                          color: context.colors.primary,
                        )
                      : context.textStyles.labelMedium)
                  ?.copyWith(
                    decoration: isToday ? TextDecoration.underline : null,
                  ),
        ),
      ],
    );
  }
}
