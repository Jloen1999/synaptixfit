import 'package:flutter/material.dart';

import '../../../../domain/models/planner/calendar_block.dart';
import '../../../../domain/models/planner/weekly_planning.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'planner_visuals.dart';

/// Aviso de solapes de la semana; al tocarlo lista las parejas.
class ConflictBanner extends StatelessWidget {
  const ConflictBanner({
    super.key,
    required this.conflicts,
    required this.titleOf,
    required this.onBlockTap,
  });

  final List<BlockConflict> conflicts;
  final String Function(CalendarBlock block) titleOf;
  final ValueChanged<CalendarBlock> onBlockTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = context.palette.warning;
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(TokensRadius.m),
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          onTap: () => _showList(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: TokensLayout.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TokensSpacing.m,
                vertical: TokensSpacing.s,
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: color, size: 20),
                  const SizedBox(width: TokensSpacing.s),
                  Expanded(
                    child: Text(
                      l10n.plannerConflictsBanner(conflicts.length),
                      style: context.textStyles.labelLarge,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showList(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = sheetContext.localizations;
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.m,
            0,
            TokensSpacing.m,
            TokensSpacing.l,
          ),
          children: [
            Text(
              l10n.plannerConflictsTitle,
              style: sheetContext.textStyles.titleMedium,
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.plannerConflictsHint,
              style: sheetContext.textStyles.bodySmall?.copyWith(
                color: sheetContext.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TokensSpacing.s),
            for (final c in conflicts)
              AppFocusOutline(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.compare_arrows_rounded,
                    color: sheetContext.palette.warning,
                  ),
                  title: Text(
                    l10n.plannerConflictPair(
                      titleOf(c.first),
                      titleOf(c.second),
                    ),
                  ),
                  // El rato en que coinciden (no el horario de uno solo): así se
                  // entiende por qué es un choque.
                  subtitle: Text(
                    l10n.plannerConflictWhen(
                      PlannerFormats.dayShort(c.overlapStart),
                      PlannerFormats.time(c.overlapStart),
                      PlannerFormats.time(c.overlapEnd),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onBlockTap(c.first);
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// Resumen compacto de la semana (estudio y deporte) que abre la carga semanal.
class WeekBalanceStrip extends StatelessWidget {
  const WeekBalanceStrip({
    super.key,
    required this.balance,
    required this.onTap,
  });

  final WeekBalance? balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final b = balance;
    return Material(
      color: context.colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(TokensRadius.m),
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: TokensLayout.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TokensSpacing.m,
                vertical: TokensSpacing.s,
              ),
              child: Wrap(
                spacing: TokensSpacing.m,
                runSpacing: TokensSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Metric(
                    icon: Icons.menu_book_rounded,
                    color: context.palette.study,
                    label: l10n.plannerStudyHours,
                    value: b == null
                        ? '–'
                        : l10n.plannerHoursProgress(
                            PlannerFormats.hours(b.actualStudyHours),
                            PlannerFormats.hours(b.plannedStudyHours),
                          ),
                  ),
                  _Metric(
                    icon: Icons.fitness_center_rounded,
                    color: context.colors.secondary,
                    label: l10n.plannerSportHours,
                    value: b == null
                        ? '–'
                        : l10n.plannerHoursProgress(
                            PlannerFormats.hours(b.actualSportHours),
                            PlannerFormats.hours(b.plannedSportHours),
                          ),
                  ),
                  if (b != null) BalanceStateChip(balance: b),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: TokensSpacing.xs),
        Text('$label ', style: context.textStyles.labelMedium),
        Text(
          value,
          style: context.textStyles.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Estado del balance con icono y texto (no solo color).
class BalanceStateChip extends StatelessWidget {
  const BalanceStateChip({super.key, required this.balance});

  final WeekBalance balance;

  @override
  Widget build(BuildContext context) => AppPill(
    label: balance.state.label(context),
    color: balance.state.color(context),
    icon: balance.state.icon,
  );
}

/// Entregas y exámenes de la semana como chips desplazables.
class WeekDeadlinesStrip extends StatelessWidget {
  const WeekDeadlinesStrip({
    super.key,
    required this.deadlines,
    required this.onTap,
  });

  final List<TimelineEntry> deadlines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.scaled(TokensLayout.minTouchTarget),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: deadlines.length,
        separatorBuilder: (_, _) => const SizedBox(width: TokensSpacing.s),
        itemBuilder: (context, i) {
          final d = deadlines[i];
          final type = d.deadlineType;
          return ActionChip(
            avatar: Icon(
              d.completed
                  ? Icons.check_circle_rounded
                  : (type?.icon ?? Icons.flag_rounded),
              size: 18,
              color: d.completed
                  ? context.palette.success
                  : context.colors.error,
            ),
            label: Text(
              '${PlannerFormats.dayShort(d.start)} · ${d.title ?? type?.label(context) ?? ''}',
            ),
            onPressed: onTap,
          );
        },
      ),
    );
  }
}
