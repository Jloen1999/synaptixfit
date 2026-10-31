import 'package:intl/intl.dart';

import '../../../../../domain/enums/notification_message_code.dart';
import '../../../../../domain/models/social/app_notification.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';

/// Textos de una notificación en el idioma de la app: los avisos automáticos
/// llegan con código y datos; los escritos a mano, con su texto tal cual.
typedef NotificationTexts = ({
  String title,
  String? description,
  String? action,
});

NotificationTexts notificationTexts(AppLocalizations l10n, AppNotification n) {
  final p = n.messageParams;
  final name = p['name'] ?? '';
  return switch (n.messageCode) {
    null => (title: n.title, description: n.description, action: n.actionLabel),
    NotificationMessageCode.challengeCompleted => (
      title: l10n.socialNotifChallengeCompletedTitle,
      description: l10n.socialNotifChallengeCompletedBody(name),
      action: l10n.socialNotifActionChallenge,
    ),
    NotificationMessageCode.badgeEarned => (
      title: l10n.socialNotifBadgeEarnedTitle,
      description: l10n.socialNotifBadgeEarnedBody(name),
      action: l10n.socialNotifActionBadges,
    ),
    NotificationMessageCode.levelUp => (
      title: l10n.socialNotifLevelUpTitle,
      description: l10n.socialNotifLevelUpBody(p['level'] ?? ''),
      action: l10n.socialNotifActionProfile,
    ),
    NotificationMessageCode.fatigueCheckIn => (
      title: l10n.socialNotifFatigueTitle,
      description: l10n.socialNotifFatigueBody,
      action: l10n.socialNotifActionTraining,
    ),
    NotificationMessageCode.overtraining => (
      title: l10n.socialNotifOvertrainingTitle,
      description: l10n.socialNotifOvertrainingBody(_ratio(p['ratio'])),
      action: l10n.socialNotifActionIndicators,
    ),
    NotificationMessageCode.postLiked => (
      title: l10n.socialNotifPostLikedTitle,
      description: l10n.socialNotifPostLikedBody(name),
      action: l10n.socialNotifActionPost,
    ),
    NotificationMessageCode.postCommented => (
      title: l10n.socialNotifPostCommentedTitle,
      description: l10n.socialNotifPostCommentedBody(name),
      action: l10n.socialNotifActionComment,
    ),
    NotificationMessageCode.friendRequestReceived => (
      title: l10n.socialNotifFriendRequestTitle,
      description: l10n.socialNotifFriendRequestBody(name),
      action: l10n.socialNotifActionRequest,
    ),
    NotificationMessageCode.friendRequestAccepted => (
      title: l10n.socialNotifFriendAcceptedTitle,
      description: l10n.socialNotifFriendAcceptedBody(name),
      action: l10n.socialNotifActionProfile,
    ),
  };
}

/// La proporción llega como «1.73»; se escribe con el separador del idioma.
String _ratio(String? raw) {
  final value = double.tryParse(raw ?? '');
  return value == null ? (raw ?? '') : NumberFormat('0.0#').format(value);
}
