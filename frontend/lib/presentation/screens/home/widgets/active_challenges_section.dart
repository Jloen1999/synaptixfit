import 'package:flutter/material.dart';

import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Retos activos (máximo 3) con su progreso.
class ActiveChallengesSection extends StatelessWidget {
  const ActiveChallengesSection({
    super.key,
    required this.challenges,
    required this.onOpen,
    required this.onSeeAll,
    required this.onCreate,
    this.now,
  });

  static const maxVisible = 3;

  final List<HomeChallenge> challenges;
  final ValueChanged<HomeChallenge> onOpen;
  final VoidCallback onSeeAll;
  final VoidCallback onCreate;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final visible = challenges.take(maxVisible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.homeChallengesTitle,
          actionLabel: challenges.isEmpty ? null : l10n.commonSeeAll,
          onAction: onSeeAll,
        ),
        if (visible.isEmpty)
          AppCard(
            child: AppEmptyState.compact(
              icon: Icons.flag_outlined,
              title: l10n.homeChallengesEmptyTitle,
              message: l10n.homeChallengesEmptyMessage,
              action: AppSecondaryButton(
                label: l10n.homeChallengesCreate,
                icon: const Icon(Icons.add_rounded),
                onPressed: onCreate,
              ),
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
            child: Column(
              children: [
                for (final challenge in visible)
                  _ChallengeTile(
                    challenge: challenge,
                    now: now ?? DateTime.now(),
                    onTap: () => onOpen(challenge),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.challenge,
    required this.now,
    required this.onTap,
  });

  final HomeChallenge challenge;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = challenge.academic
        ? context.palette.study
        : context.colors.secondary;
    final endsAt = challenge.endsAt;
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = endsAt == null
        ? null
        : DateTime(
            endsAt.year,
            endsAt.month,
            endsAt.day,
          ).difference(today).inDays.clamp(0, 9999);
    final progress = challenge.progress.round();

    return AppFocusOutline(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TokensSpacing.m,
            vertical: TokensSpacing.s,
          ),
          child: Row(
            children: [
              Tooltip(
                message: challenge.academic
                    ? l10n.homeChallengeAcademic
                    : l10n.homeChallengeFitness,
                child: Icon(
                  challenge.academic
                      ? Icons.school_outlined
                      : Icons.fitness_center_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: context.textStyles.bodyLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          l10n.homeChallengeProgress(progress),
                          style: context.textStyles.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(TokensRadius.pill),
                      child: LinearProgressIndicator(
                        value: challenge.progress / 100,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.16),
                      ),
                    ),
                    if (daysLeft != null) ...[
                      const SizedBox(height: TokensSpacing.xs),
                      Text(
                        l10n.homeChallengeEndsIn(daysLeft),
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: TokensSpacing.s),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
