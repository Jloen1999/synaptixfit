import 'package:flutter/material.dart';

import '../../../../domain/enums/challenge_status.dart';
import '../../../../domain/models/challenges/challenge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'challenge_date_block.dart';
import 'challenge_labels.dart';
import 'challenge_next_step.dart';

/// Tarjeta de un reto en los listados (propios o de la comunidad), pensada
/// para leerse de un vistazo y en este orden: cuándo toca (bloque de fecha a
/// la izquierda y la frase «Vence en 3 días», en aviso si urge), qué reto es,
/// cuánto lleva y qué toca ahora. El tipo (académico o físico) va en el acento
/// del progreso y en una pastilla; la racha, solo si la hay.
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
    final now = DateTime.now();
    final accent = challenge.type.color(context);
    final status = challenge.status;
    // El aviso es para lo que urge (hoy o mañana); lo vencido ya no urge.
    final urgent = challenge.isUrgentAt(now);
    final nextStep = challengeNextStepText(context, challenge);
    final percent = (challenge.progressFraction * 100).round();
    final counts = challenge.tracksTrainingSessions
        ? l10n.challengesSessionsProgress(
            challenge.sessionsCompleted,
            challenge.sessionTarget ?? 0,
          )
        : challenge.hasMilestones
        ? l10n.challengesMilestonesProgress(
            challenge.completedMilestoneCount,
            challenge.milestoneCount,
          )
        : null;
    final clone = onClone == null
        ? null
        : IconButton(
            tooltip: l10n.challengesCloneTooltip,
            onPressed: cloning ? null : onClone,
            icon: cloning
                ? const SizedBox.square(
                    dimension: TokensSize.iconS,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.library_add_outlined),
          );
    // Con el texto grande o poco ancho, el bloque de fecha pasa a ser una
    // franja de una línea encima y el contenido usa todo el ancho.
    Widget body(BuildContext context, bool compact) {
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lo primero que se lee es cuándo toca, en palabras.
          Text(
            challenge.whenText(context, now),
            style: context.textStyles.labelLarge?.copyWith(
              color: urgent
                  ? context.palette.warning
                  : context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.xxs),
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
          const SizedBox(height: TokensSpacing.s),
          // Al lado de la barra, solo el porcentaje: con el texto al
          // 200 % una etiqueta larga no dejaría sitio a la barra.
          AppCycleProgress(
            progress: challenge.progressFraction,
            label: l10n.challengesProgressPercent(percent),
            semanticsLabel: l10n.challengesProgressSemantics(percent),
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
                ChallengeStatus.expired => context.colors.onSurfaceVariant,
                ChallengeStatus.upcoming => context.colors.onSurfaceVariant,
                ChallengeStatus.active => context.colors.primary,
              },
            ),
          ],
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.xs,
            children: [
              AppPill(
                icon: challenge.type.icon,
                label: challenge.type.label(context),
                color: accent,
              ),
              if (counts != null)
                AppPill(
                  icon: challenge.tracksTrainingSessions
                      ? Icons.repeat_rounded
                      : Icons.checklist_rounded,
                  label: counts,
                ),
              if (challenge.currentStreak > 0)
                AppPill(
                  icon: Icons.local_fire_department_rounded,
                  label: l10n.challengesStreakDays(challenge.currentStreak),
                  color: context.palette.streak,
                ),
            ],
          ),
        ],
      );
      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChallengeDateBlock(challenge: challenge, now: now, compact: true),
            const SizedBox(height: TokensSpacing.s),
            content,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChallengeDateBlock(challenge: challenge, now: now),
          const SizedBox(width: TokensSpacing.m),
          Expanded(child: content),
        ],
      );
    }

    bool compactFor(BuildContext context, BoxConstraints constraints) =>
        !AppDateBlock.sideBySide(context, constraints.maxWidth);

    if (clone == null) {
      return AppCard(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) =>
              body(context, compactFor(context, constraints)),
        ),
      );
    }
    // Reto ajeno: la tarjeta no es pulsable entera; abrirlo y «clonar» son
    // botones hermanos (sin toques anidados).
    return AppCard(
      padding: const EdgeInsets.all(TokensSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = compactFor(context, constraints);
          final area = AppCardTapArea(
            onTap: onTap,
            padding: const EdgeInsets.all(TokensSpacing.sm),
            child: body(context, compact),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                area,
                Align(alignment: AlignmentDirectional.centerEnd, child: clone),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: area),
              clone,
            ],
          );
        },
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
