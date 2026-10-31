import 'package:flutter/material.dart';

import '../../../../domain/enums/challenge_status.dart';
import '../../../../domain/models/challenges/challenge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../widgets/widgets.dart';
import 'challenge_labels.dart';

/// Días a partir de los que el plazo se marca como urgente (pastilla de aviso).
const _urgentDays = 3;

/// Pastilla de plazo: en un reto activo, el tiempo que queda (en aviso si
/// quedan [_urgentDays] días o menos); si no, su estado (completado o vencido).
/// Lleva siempre texto: el color nunca es la única señal.
class ChallengeTimePill extends StatelessWidget {
  const ChallengeTimePill({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final status = challenge.status;
    if (status != ChallengeStatus.active) {
      return AppPill(
        icon: status.icon,
        label: status.label(context),
        color: status.color(context),
      );
    }
    final l10n = context.localizations;
    final days = ChallengeFormats.daysLeft(challenge.endAt, DateTime.now());
    final urgent = days <= _urgentDays;
    return AppPill(
      icon: urgent ? Icons.hourglass_bottom_rounded : Icons.event_outlined,
      label: days <= 7
          ? l10n.challengesDaysLeft(days < 0 ? 0 : days)
          : l10n.challengesEndsOn(ChallengeFormats.shortDate(challenge.endAt)),
      color: urgent ? context.palette.warning : context.colors.onSurfaceVariant,
    );
  }
}

/// Qué hacer ahora con un reto propio, en una frase: la siguiente tarea, las
/// sesiones que faltan, la recompensa conseguida o cómo seguir si venció.
/// `null` si no hay nada útil que decir (reto ajeno o sin datos de tareas).
String? challengeNextStepText(BuildContext context, Challenge challenge) {
  if (!challenge.owned) return null;
  final l10n = context.localizations;
  switch (challenge.status) {
    case ChallengeStatus.completed:
      final xp = challenge.totalXpAwarded;
      return xp > 0
          ? l10n.challengesCompletedReward(xp)
          : l10n.challengesCompletedNoXp;
    case ChallengeStatus.expired:
      return l10n.challengesExpiredHint;
    case ChallengeStatus.active:
      if (challenge.tracksTrainingSessions) {
        return l10n.challengesSessionsLeft(challenge.sessionsRemaining);
      }
      final next = challenge.nextMilestone;
      if (next != null) return l10n.challengesNextStep(next.title);
      // Con tareas pero sin su detalle (listado) no se inventa el paso.
      if (challenge.hasMilestones) return null;
      return l10n.challengesNextMarkDone;
  }
}

/// Icono que acompaña a [challengeNextStepText] según el estado del reto.
IconData challengeNextStepIcon(Challenge challenge) =>
    switch (challenge.status) {
      ChallengeStatus.completed => Icons.emoji_events_rounded,
      ChallengeStatus.expired => Icons.update_rounded,
      ChallengeStatus.active => Icons.arrow_forward_rounded,
    };
