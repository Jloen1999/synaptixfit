import 'package:flutter/material.dart';

import '../../../../domain/enums/challenge_status.dart';
import '../../../../domain/models/challenges/challenge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'challenge_labels.dart';
import 'challenge_next_step.dart';
import 'challenge_progress_bar.dart';

/// Tarjeta de un reto en los listados (propios o de la comunidad): título,
/// plazo, progreso, siguiente paso y datos de motivación (racha, tareas).
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

  /// Solo en retos ajenos: lo añade a los retos propios.
  final VoidCallback? onClone;
  final bool cloning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final accent = challenge.type.color(context);
    final status = challenge.status;
    final nextStep = challengeNextStepText(context, challenge);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(TokensSpacing.s),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: AppPill.tintAlpha),
                    borderRadius: BorderRadius.circular(TokensRadius.m),
                  ),
                  child: Icon(
                    challenge.type.icon,
                    color: accent,
                    size: TokensSize.iconS,
                  ),
                ),
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
                    const SizedBox(height: TokensSpacing.xs),
                    // El plazo va bajo el título (no a su lado): con el texto
                    // al 200 % no le quita ancho al nombre del reto.
                    ChallengeTimePill(challenge: challenge),
                  ],
                ),
              ),
              if (onClone != null) ...[
                const SizedBox(width: TokensSpacing.s),
                IconButton(
                  tooltip: l10n.challengesCloneTooltip,
                  onPressed: cloning ? null : onClone,
                  icon: cloning
                      ? const SizedBox.square(
                          dimension: TokensSize.iconS,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.library_add_outlined),
                ),
              ],
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          ChallengeProgressBar(
            value: challenge.progressFraction,
            color: status == ChallengeStatus.completed
                ? context.palette.success
                : accent,
          ),
          if (nextStep != null) ...[
            const SizedBox(height: TokensSpacing.s),
            _NextStepLine(
              icon: challengeNextStepIcon(challenge),
              text: nextStep,
              color: switch (status) {
                ChallengeStatus.completed => context.palette.accent,
                ChallengeStatus.expired => context.palette.warning,
                ChallengeStatus.active => context.colors.primary,
              },
            ),
          ],
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.m,
            runSpacing: TokensSpacing.xs,
            children: [
              if (status != ChallengeStatus.active)
                _Meta(
                  icon: Icons.event_outlined,
                  text: l10n.challengesEndedOn(
                    ChallengeFormats.shortDate(challenge.endAt),
                  ),
                ),
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

/// Frase de «siguiente paso» con su icono de color (el texto va en el color
/// normal para mantener el contraste).
class _NextStepLine extends StatelessWidget {
  const _NextStepLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: TokensSize.iconXs, color: color),
        const SizedBox(width: TokensSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
        Icon(icon, size: TokensSize.iconXs, color: c),
        const SizedBox(width: TokensSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: context.textStyles.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
