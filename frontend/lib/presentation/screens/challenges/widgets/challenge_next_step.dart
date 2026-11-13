import 'package:flutter/material.dart';

import '../../../../domain/enums/challenge_status.dart';
import '../../../../domain/models/challenges/challenge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../widgets/widgets.dart';
import 'challenge_labels.dart';

/// Pastilla de plazo: cuándo toca el reto en palabras de cada día («Vence
/// hoy», «Vence en 3 días», «Empieza el 10 nov»), en color de aviso si vence
/// hoy o mañana; completado o vencido, su estado. Lleva siempre texto: el
/// color nunca es la única señal.
class ChallengeTimePill extends StatelessWidget {
  const ChallengeTimePill({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final status = challenge.status;
    final now = DateTime.now();
    if (status == ChallengeStatus.completed ||
        status == ChallengeStatus.expired) {
      return AppPill(
        icon: status.icon,
        label: status.label(context),
        color: status.color(context),
      );
    }
    final urgent = challenge.isUrgentAt(now);
    return AppPill(
      icon: status == ChallengeStatus.upcoming
          ? status.icon
          : urgent
          ? Icons.hourglass_bottom_rounded
          : Icons.event_outlined,
      label: challenge.whenText(context, now),
      color: urgent ? context.palette.warning : context.colors.onSurfaceVariant,
    );
  }
}

/// Qué hacer ahora con un reto propio, en una frase: la siguiente tarea, las
/// sesiones que faltan, qué lo completa si va vinculado, cuándo empieza, la
/// recompensa conseguida o cómo seguir si venció. `null` si no hay nada útil
/// que decir (reto ajeno).
String? challengeNextStepText(BuildContext context, Challenge challenge) {
  if (!challenge.owned) return null;
  final l10n = context.localizations;
  switch (challenge.status) {
    case ChallengeStatus.completed:
      return l10n.challengesCompletedNoXp;
    case ChallengeStatus.expired:
      return l10n.challengesExpiredHint;
    case ChallengeStatus.upcoming:
      return l10n.challengesUpcomingHint(
        ChallengeFormats.weekdayDate(challenge.startAt),
      );
    case ChallengeStatus.active:
      if (challenge.tracksTrainingSessions) {
        return l10n.challengesSessionsLeft(challenge.sessionsRemaining);
      }
      if (challenge.completedByLink) {
        final title = challenge.linkTitle;
        return title == null
            ? l10n.challengesCompletedByDeadlineGeneric
            : l10n.challengesCompletedByDeadline(title);
      }
      final next = challenge.nextMilestone;
      if (next != null) return l10n.challengesNextStep(next.title);
      // Las tareas que quedan avanzan solas (entrega o bloques): se dice cuál.
      for (final m in challenge.milestones) {
        if (!m.completed && m.completedByLink) {
          return l10n.challengesNextStep(m.title);
        }
      }
      if (challenge.hasMilestones) return null;
      return l10n.challengesNextMarkDone;
  }
}

/// Icono que acompaña a [challengeNextStepText] según el estado del reto.
IconData challengeNextStepIcon(Challenge challenge) =>
    switch (challenge.status) {
      ChallengeStatus.completed => Icons.emoji_events_rounded,
      ChallengeStatus.expired => Icons.update_rounded,
      ChallengeStatus.upcoming => Icons.schedule_rounded,
      ChallengeStatus.active =>
        challenge.completedByLink
            ? Icons.link_rounded
            : Icons.arrow_forward_rounded,
    };
