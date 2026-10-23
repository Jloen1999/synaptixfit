import 'package:flutter/material.dart';

import '../../../../domain/models/training/routine.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'training_labels.dart';

/// Tarjeta de rutina para listados (propias o de la comunidad).
class RoutineSummaryCard extends StatelessWidget {
  const RoutineSummaryCard({
    super.key,
    required this.routine,
    required this.onTap,
    this.showAuthor = false,
    this.trailing,
  });

  final RoutineSummary routine;
  final VoidCallback onTap;
  final bool showAuthor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final r = routine;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: context.textStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showAuthor && r.authorName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: TokensSpacing.xxs),
                        child: Row(
                          children: [
                            AppAvatar(name: r.authorName!, radius: 10),
                            const SizedBox(width: TokensSpacing.xs),
                            Flexible(
                              child: Text(
                                l10n.trainingByAuthor(r.authorName!),
                                style: context.textStyles.labelMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (r.description != null && r.description!.trim().isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(
              r.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.xs,
            runSpacing: TokensSpacing.xs,
            children: [
              if (!showAuthor)
                AppPill(
                  icon: r.status.icon,
                  label: r.status.label(l10n),
                  color: context.colors.secondary,
                ),
              AppPill(
                icon: Icons.calendar_view_week_rounded,
                label: l10n.trainingWeeksCount(r.durationWeeks),
              ),
              AppPill(
                icon: Icons.fitness_center_rounded,
                label: l10n.trainingExercisesCount(r.exerciseCount),
              ),
              if (r.goal != null)
                AppPill(icon: Icons.flag_outlined, label: r.goal!.label(l10n)),
            ],
          ),
          if (!showAuthor && r.totalDays > 0) ...[
            const SizedBox(height: TokensSpacing.s),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(TokensRadius.pill),
                    child: LinearProgressIndicator(
                      value: r.progress,
                      color: context.colors.secondary,
                      backgroundColor: context.colors.secondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: TokensSpacing.s),
                Text(
                  l10n.trainingDaysProgress(r.completedDays, r.totalDays),
                  style: context.textStyles.labelMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
