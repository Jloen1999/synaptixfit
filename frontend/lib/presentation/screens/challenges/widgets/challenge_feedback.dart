import 'package:flutter/widgets.dart';

import '../../../extensions/context_extensions.dart';

/// Compone el aviso tras una acción con XP: mensaje base, XP ganada o
/// restada y tareas desbloqueadas.
String challengeFeedbackMessage(
  BuildContext context, {
  required String base,
  int xpDelta = 0,
  int unlockedCount = 0,
  List<String> unlockedTitles = const [],
}) {
  final l10n = context.localizations;
  var message = base;
  if (xpDelta != 0) {
    message = l10n.challengesFeedbackJoin(
      message,
      xpDelta > 0
          ? l10n.challengesXpGain(xpDelta)
          : l10n.challengesXpLoss(-xpDelta),
    );
  }
  if (unlockedTitles.isNotEmpty) {
    message = l10n.challengesFeedbackJoin(
      message,
      l10n.challengesUnlockedNamed(unlockedTitles.join(', ')),
    );
  } else if (unlockedCount > 0) {
    message = l10n.challengesFeedbackJoin(
      message,
      l10n.challengesUnlocked(unlockedCount),
    );
  }
  return message;
}
