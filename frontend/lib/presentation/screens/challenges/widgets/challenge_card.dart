import 'package:flutter/material.dart';

import '../../../../domain/enums/challenge_status.dart';
import '../../../../domain/models/challenges/challenge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'challenge_labels.dart';
import 'challenge_progress_bar.dart';

/// Tarjeta de un reto en los listados (propios o de la comunidad).
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onTap,
    this.onClone,
    this.cloning = false,
  });

  final Challenge challenge;
  final VoidCallback onTap;

  /// Solo en retos ajenos: clona el reto.
  final VoidCallback? onClone;
  final bool cloning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final accent = challenge.type.color(context);
    final status = challenge.status;
    final days = ChallengeFormats.daysLeft(challenge.endAt, DateTime.now());
    final dateText = status == ChallengeStatus.active
        ? (days <= 7
              ? l10n.challengesDaysLeft(days < 0 ? 0 : days)
              : l10n.challengesEndsOn(
                  ChallengeFormats.shortDate(challenge.endAt),
                ))
        : l10n.challengesEndedOn(ChallengeFormats.shortDate(challenge.endAt));
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(TokensSpacing.s),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(TokensRadius.m),
                ),
                child: Icon(challenge.type.icon, color: accent, size: 20),
              ),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleMedium,
                    ),
                    if (!challenge.owned) ...[
                      const SizedBox(height: TokensSpacing.xxs),
                      Text(
                        l10n.challengesByAuthor(
                          challenge.ownerName ?? l10n.challengesUnknownAuthor,
                        ),
                        style: context.textStyles.labelMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: TokensSpacing.s),
              if (onClone != null)
                IconButton(
                  tooltip: l10n.challengesCloneTooltip,
                  onPressed: cloning ? null : onClone,
                  icon: cloning
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.copy_all_rounded),
                )
              else
                AppPill(
                  icon: status.icon,
                  label: status.label(context),
                  color: status.color(context),
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          ChallengeProgressBar(
            value: challenge.progressFraction,
            color: status == ChallengeStatus.completed
                ? context.palette.success
                : accent,
          ),
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.m,
            runSpacing: TokensSpacing.xs,
            children: [
              _Meta(icon: Icons.event_outlined, text: dateText),
              if (challenge.hasMilestones)
                _Meta(
                  icon: Icons.checklist_rounded,
                  text: l10n.challengesMilestonesProgress(
                    challenge.completedMilestoneCount,
                    challenge.milestoneCount,
                  ),
                ),
              if (challenge.tracksTrainingSessions)
                _Meta(
                  icon: Icons.repeat_rounded,
                  text: l10n.challengesSessionsProgress(
                    challenge.sessionsCompleted,
                    challenge.sessionTarget ?? 0,
                  ),
                ),
              if (challenge.currentStreak > 0)
                _Meta(
                  icon: Icons.local_fire_department_rounded,
                  text: l10n.challengesStreakDays(challenge.currentStreak),
                  color: context.palette.streak,
                ),
              _Meta(
                icon: challenge.difficulty.icon,
                text: challenge.difficulty.effortLabel(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: TokensSpacing.xs),
        Text(
          text,
          style: context.textStyles.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
