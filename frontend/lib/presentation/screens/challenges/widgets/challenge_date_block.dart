import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/challenge_status.dart';
import '../../../../domain/models/challenges/challenge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../widgets/widgets.dart';
import 'challenge_labels.dart';

/// Bloque de fecha a la izquierda de la tarjeta de un reto ([AppDateBlock]
/// con los textos de los retos): dice de un vistazo a qué día pertenece
/// («Hoy · 3 · nov», «lun · 10 · nov», «Empieza · 10 · nov», «Venció · 2 · nov»).
/// Se tiñe de aviso solo si vence hoy o mañana, de éxito si está hecho y del
/// acento de su tipo si no. Con [compact] (texto grande o poco ancho) es una
/// franja de una línea que va encima del contenido. Es decorativo: la tarjeta
/// ya lee la frase de [ChallengeWhenOf.whenText].
class ChallengeDateBlock extends StatelessWidget {
  const ChallengeDateBlock({
    super.key,
    required this.challenge,
    required this.now,
    this.compact = false,
  });

  final Challenge challenge;
  final DateTime now;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final day = DateFormat.d();
    final month = DateFormat.MMM();
    final String caption;
    String? headline;
    String? footer;
    final Color color;
    switch (challenge.status) {
      case ChallengeStatus.completed:
        caption = l10n.challengesDateDone;
        color = context.palette.success;
      case ChallengeStatus.expired:
        // Ya no urge: lo pasado no lleva el color de aviso.
        caption = l10n.challengesDateExpired;
        color = context.colors.onSurfaceVariant;
        headline = day.format(challenge.endAt);
        footer = month.format(challenge.endAt);
      case ChallengeStatus.upcoming:
        caption = l10n.challengesDateStarts;
        color = context.colors.onSurfaceVariant;
        headline = day.format(challenge.startAt);
        footer = month.format(challenge.startAt);
      case ChallengeStatus.active:
        final days = ChallengeFormats.daysLeft(challenge.endAt, now);
        color = challenge.isUrgentAt(now)
            ? context.palette.warning
            : challenge.type.color(context);
        // Como [AppDateBlock.due]: la cifra es siempre el día y «Hoy» o
        // «Mañana» van arriba (en grande, una palabra larga no cabría).
        // Un reto activo nunca se pinta como vencido: lo decide el servidor.
        caption = days <= 0
            ? l10n.challengesDateToday
            : days == 1
            ? l10n.challengesDateTomorrow
            : DateFormat.E().format(challenge.endAt);
        headline = day.format(challenge.endAt);
        footer = month.format(challenge.endAt);
    }
    return AppDateBlock(
      caption: caption,
      headline: headline,
      footer: footer,
      color: color,
      icon: Icons.emoji_events_rounded,
      compact: compact,
    );
  }
}
