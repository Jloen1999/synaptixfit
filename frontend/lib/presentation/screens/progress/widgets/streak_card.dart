import 'package:flutter/material.dart';

import '../../../../domain/models/progress/streak.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'progress_labels.dart';

/// Detalle de la racha (en «Ver más» de Progreso): días, récord, días libres
/// e hitos. El resumen de una línea lo da `WeekHeadlineCard`.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = context.palette.streak;
    final next = streak.nextMilestone;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TokensSpacing.s),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: AppPill.tintAlpha),
                  borderRadius: BorderRadius.circular(TokensRadius.m),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: color,
                  size: TokensSize.iconM,
                ),
              ),
              const SizedBox(width: TokensSpacing.m),
              // Todo en una columna: con el texto al 200 % nada se aplasta.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.progressStreakTitle,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      l10n.progressStreakDays(streak.currentDays),
                      style: context.textStyles.headlineSmall,
                    ),
                    Text(
                      l10n.progressStreakBest(streak.bestDays),
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    if (streak.activeToday)
                      _StatusChip(
                        icon: Icons.check_circle_rounded,
                        label: l10n.progressStreakActiveToday,
                        color: context.palette.success,
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Días libres (comodines en el servidor): cuántos quedan y, si alguno
          // salvó la racha, cuándo. El aviso de riesgo va en el titular.
          const SizedBox(height: TokensSpacing.m),
          AppHelpToggle(
            help: l10n.progressStreakFreezesHelp,
            tooltip: l10n.commonHelpAbout(l10n.progressStreakFreezesAbout),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.ac_unit_rounded,
                    color: streak.freezesAvailable > 0
                        ? context.colors.tertiary
                        : context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Text(
                    [
                      l10n.progressStreakFreezes(streak.freezesAvailable),
                      if (streak.frozenDays.isNotEmpty)
                        l10n.progressStreakFrozen(
                          ProgressFormat.date(streak.frozenDays.last),
                        ),
                    ].join(' '),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
          if (next != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(TokensRadius.pill),
              child: LinearProgressIndicator(
                value: streak.milestoneProgress,
                color: color,
                backgroundColor: context.palette.accentContainer,
              ),
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.progressStreakNextMilestone(
                streak.daysToNextMilestone,
                next,
              ),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ] else
            Text(
              l10n.progressStreakAllMilestones,
              style: context.textStyles.bodySmall,
            ),
          const SizedBox(height: TokensSpacing.m),
          Row(
            children: [
              for (final milestone in Streak.milestones) ...[
                Expanded(
                  child: _MilestoneChip(
                    days: milestone,
                    // Lo decide el servidor (`StreakStatus`): sin reglas aquí.
                    reached: streak.reachedMilestones.contains(milestone),
                  ),
                ),
                if (milestone != Streak.milestones.last)
                  const SizedBox(width: TokensSpacing.s),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.days, required this.reached});

  final int days;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = reached
        ? context.palette.onAccent
        : context.colors.onSurfaceVariant;
    return Semantics(
      label: reached
          ? l10n.progressStreakMilestoneReached(days)
          : l10n.progressStreakMilestonePending(days),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: TokensSpacing.s),
        decoration: BoxDecoration(
          color: reached
              ? context.palette.accent
              : context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(TokensRadius.s),
          border: Border.all(
            color: reached
                ? context.palette.accent
                : context.colors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              reached ? Icons.check_rounded : Icons.flag_outlined,
              size: TokensSize.iconXs,
              color: color,
            ),
            const SizedBox(width: TokensSpacing.xxs),
            Flexible(
              child: Text(
                l10n.progressStreakMilestoneShort(days),
                style: context.textStyles.labelMedium?.copyWith(color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: TokensSize.iconXs, color: color),
        const SizedBox(width: TokensSpacing.xxs),
        Text(
          label,
          style: context.textStyles.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
