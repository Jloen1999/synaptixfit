import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../domain/models/training/training_week.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';

/// «Esta semana» en Gimnasio (ADR 0055): siete puntos, de lunes a domingo.
/// Hecho lleva ✓, lo que toca un aro y hoy va marcado; qué es cada día lo
/// decide el servidor ([TrainingWeek]). Tocar un día hecho abre ese entreno y
/// uno que toca, la rutina.
class TrainingWeekStrip extends StatelessWidget {
  const TrainingWeekStrip({
    super.key,
    required this.week,
    required this.onOpenSession,
    this.onOpenPlanned,
  });

  final TrainingWeek week;
  final ValueChanged<String> onOpenSession;

  /// Nulo si no hay rutina que abrir.
  final VoidCallback? onOpenPlanned;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    // Margen lateral pequeño: los siete días van en una fila y así llegan a
    // 48 dp de ancho desde 390 dp de pantalla (excepción de accessibility.md).
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.s,
        vertical: TokensSpacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.s),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.trainingThisWeek,
                      style: context.textStyles.titleMedium,
                    ),
                  ),
                ),
                if (week.total > 0)
                  Text(
                    l10n.trainingWeekDoneOfTotal(week.done, week.total),
                    style: context.textStyles.labelLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          Row(
            children: [
              for (final day in week.days)
                Expanded(
                  child: _DayDot(
                    day: day,
                    onTap: switch (day.state) {
                      TrainingDayState.done when day.sessionId != null =>
                        () => onOpenSession(day.sessionId!),
                      TrainingDayState.planned => onOpenPlanned,
                      _ => null,
                    },
                  ),
                ),
            ],
          ),
          // Sin nada hecho ni previsto, siete círculos grises no dicen nada.
          if (week.total == 0) ...[
            const SizedBox(height: TokensSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.s),
              child: Text(
                l10n.trainingWeekEmpty,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day, required this.onTap});

  final TrainingWeekDay day;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    final locale = l10n.localeName;
    final name = toBeginningOfSentenceCase(
      DateFormat.EEEE(locale).format(day.date),
    );
    final stateText = switch (day.state) {
      TrainingDayState.done => l10n.trainingWeekStateDone,
      TrainingDayState.planned => l10n.trainingWeekStatePlanned,
      TrainingDayState.free => l10n.trainingWeekStateFree,
    };
    final success = context.palette.success;
    final dot = switch (day.state) {
      TrainingDayState.done => Container(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            success.withValues(alpha: AppPill.tintAlpha),
            colors.surface,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          size: TokensSize.iconS,
          color: success,
        ),
      ),
      TrainingDayState.planned => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.primary,
            width: TokensSize.weekDotRing,
          ),
        ),
      ),
      TrainingDayState.free => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surfaceContainerHigh,
        ),
      ),
    };
    // La acción va también en el nodo del lector (con `excludeSemantics`, el
    // toque del InkWell no le llegaría) y dice qué abre.
    return Semantics(
      button: onTap != null,
      onTap: onTap,
      onTapHint: onTap == null
          ? null
          : day.state == TrainingDayState.done
          ? l10n.trainingWeekOpenWorkout
          : l10n.trainingSeeRoutine,
      label: [
        if (day.today) '$name, ${l10n.commonDateToday}' else name,
        stateText,
      ].join(': '),
      excludeSemantics: true,
      child: AppFocusOutline(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensRadius.m),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: TokensLayout.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(dimension: TokensSize.iconL, child: dot),
                  const SizedBox(height: TokensSpacing.xxs),
                  Text(
                    DateFormat('EEEEE', locale).format(day.date).toUpperCase(),
                    style: day.today
                        ? context.textStyles.titleSmall?.copyWith(
                            color: colors.primary,
                          )
                        : context.textStyles.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                  ),
                  // Hoy, además del color: una rayita bajo la letra.
                  Container(
                    width: TokensSize.weekTodayMarkWidth,
                    height: TokensSize.weekTodayMarkHeight,
                    decoration: BoxDecoration(
                      color: day.today ? colors.primary : null,
                      borderRadius: BorderRadius.circular(TokensRadius.pill),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
