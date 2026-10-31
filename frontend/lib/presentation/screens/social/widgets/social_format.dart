import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/post_type.dart';
import '../../../../domain/models/social/post_link.dart';
import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';

/// Tiempo relativo corto («ahora», «hace 5 min», «hace 3 h», «hace 2 d» o fecha).
String socialTimeAgo(AppLocalizations l10n, DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.inMinutes < 1) return l10n.socialTimeNow;
  if (diff.inHours < 1) return l10n.socialTimeMinutes(diff.inMinutes);
  if (diff.inDays < 1) return l10n.socialTimeHours(diff.inHours);
  if (diff.inDays < 7) return l10n.socialTimeDays(diff.inDays);
  return DateFormat('d MMM yyyy').format(date);
}

/// Etiqueta, icono y color de cada tipo de publicación.
extension PostTypeStyle on PostType {
  String label(AppLocalizations l10n) => switch (this) {
    PostType.sessionCompleted => l10n.socialPostTypeSession,
    PostType.challengeCompleted => l10n.socialPostTypeChallengeCompleted,
    PostType.milestoneReached => l10n.socialPostTypeMilestone,
    PostType.badgeUnlocked => l10n.socialPostTypeBadge,
    PostType.routine => l10n.socialPostTypeRoutine,
    PostType.challenge => l10n.socialPostTypeChallenge,
  };

  IconData get icon => switch (this) {
    PostType.sessionCompleted => Icons.fitness_center_rounded,
    PostType.challengeCompleted => Icons.emoji_events_rounded,
    PostType.milestoneReached => Icons.workspace_premium_rounded,
    PostType.badgeUnlocked => Icons.military_tech_rounded,
    PostType.routine => Icons.list_alt_rounded,
    PostType.challenge => Icons.flag_rounded,
  };

  /// Entrenamiento en `secondary`; logros en `palette.accent`; retos en `primary`.
  Color color(BuildContext context) => switch (this) {
    PostType.sessionCompleted || PostType.routine => context.colors.secondary,
    PostType.challengeCompleted ||
    PostType.milestoneReached ||
    PostType.badgeUnlocked => context.palette.accent,
    PostType.challenge => context.colors.primary,
  };
}

/// Icono y ruta del contenido enlazado en una publicación.
extension PostLinkStyle on PostLink {
  IconData get icon => switch (kind) {
    PostLinkKind.routine => Icons.fitness_center_rounded,
    PostLinkKind.challenge => Icons.flag_rounded,
    PostLinkKind.badge => Icons.military_tech_rounded,
  };

  /// Ruta de otro módulo (ver el mapa de rutas compartido) o `null`.
  String? get route => switch (kind) {
    PostLinkKind.routine when id != null => '/training/routines/$id',
    PostLinkKind.challenge when id != null => '/challenges/$id',
    PostLinkKind.badge => '/progress/badges',
    _ => null,
  };
}
