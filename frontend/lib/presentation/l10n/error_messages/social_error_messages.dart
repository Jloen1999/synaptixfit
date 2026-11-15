import '../gen_l10n/app_localizations.dart';

/// Códigos de error del módulo social (publicaciones, comentarios, amistades,
/// usuarios y notificaciones).
String? socialErrorMessage(
  AppLocalizations l10n,
  String code,
) => switch (code) {
  'POST_NOT_FOUND' => l10n.socialErrorPostNotFound,
  'POST_FORBIDDEN' => l10n.socialErrorPostForbidden,
  'POST_ALREADY_SHARED' => l10n.socialErrorPostAlreadyShared,
  'POST_TYPE_NOT_ALLOWED' => l10n.socialErrorPostTypeNotAllowed,
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
  'FRIEND_CHALLENGE_NOT_FOUND' => l10n.socialErrorFriendChallengeNotFound,
  'FRIEND_STREAK_NOT_FOUND' => l10n.socialErrorFriendStreakNotFound,
  'WORKOUT_TOGETHER_NOT_FOUND' => l10n.socialErrorWorkoutTogetherNotFound,
  'TOGETHER_NOT_FRIENDS' => l10n.socialErrorTogetherNotFriends,
  'TOGETHER_GROUP_SIZE' => l10n.socialErrorTogetherGroupSize,
  'TOGETHER_INVALID_STATE' => l10n.socialErrorTogetherInvalidState,
  'FRIEND_CHALLENGE_TEMPLATE_NOT_ALLOWED' =>
    l10n.socialErrorFriendChallengeTemplateNotAllowed,
  'FRIEND_STREAK_LIMIT_REACHED' => l10n.socialErrorFriendStreakLimitReached,
  'FRIEND_STREAK_ALREADY_EXISTS' => l10n.socialErrorFriendStreakAlreadyExists,
  'FRIEND_STREAK_NUDGE_UNAVAILABLE' =>
    l10n.socialErrorFriendStreakNudgeUnavailable,
  'USER_REPORT_NOT_FOUND' => l10n.socialErrorUserReportNotFound,
  _ => null,
};
