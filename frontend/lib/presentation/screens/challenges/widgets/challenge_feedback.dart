import 'package:flutter/widgets.dart';

import '../../../extensions/context_extensions.dart';

/// Compone el aviso tras una acción de un reto: mensaje base y tareas
/// desbloqueadas. Sin la XP ganada o restada: se ve en Progreso (ADR 0038).
String challengeFeedbackMessage(
  BuildContext context, {
  required String base,
  int unlockedCount = 0,
  List<String> unlockedTitles = const [],
}) {
  final l10n = context.localizations;
  var message = base;
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
