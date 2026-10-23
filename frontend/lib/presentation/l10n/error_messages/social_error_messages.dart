import '../gen_l10n/app_localizations.dart';

/// Códigos de error del módulo social (publicaciones, comentarios, amistades,
/// usuarios y notificaciones).
String? socialErrorMessage(
  AppLocalizations l10n,
  String code,
) => switch (code) {
  'POST_NOT_FOUND' => l10n.socialErrorPostNotFound,
  'POST_FORBIDDEN' => l10n.socialErrorPostForbidden,
  'COMMENT_NOT_FOUND' => l10n.socialErrorCommentNotFound,
  'COMMENT_FORBIDDEN' => l10n.socialErrorCommentForbidden,
  'FRIENDSHIP_NOT_FOUND' => l10n.socialErrorFriendshipNotFound,
  'FRIENDSHIP_ALREADY_EXISTS' => l10n.socialErrorFriendshipAlreadyExists,
  'FRIENDSHIP_SELF_TARGET' => l10n.socialErrorFriendshipSelfTarget,
  'FRIENDSHIP_INVALID_STATE' => l10n.socialErrorFriendshipInvalidState,
  'FRIENDSHIP_BLOCKED' => l10n.socialErrorFriendshipBlocked,
  'SOCIAL_USER_NOT_FOUND' => l10n.socialErrorSocialUserNotFound,
  'SOCIAL_CANNOT_REPORT_OWN_CONTENT' => l10n.socialErrorSocialCannotReportOwn,
  'NOTIFICATION_NOT_FOUND' => l10n.socialErrorNotificationNotFound,
  'NOTIFICATION_INVALID_QUIET_HOURS' => l10n.socialErrorNotificationQuietHours,
  _ => null,
};
