import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/errors/app_error.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';

part 'social_feedback.freezed.dart';

// Estado que comparten los blocs del módulo social (carga y avisos de una
// vez); la página los pinta con `showSocialFeedback` (widgets/).

/// Estado de carga de una lista o pantalla del módulo social.
enum SocialLoadStatus { loading, loaded, failure }

/// Confirmaciones que se muestran en un SnackBar tras una acción.
enum SocialMessage {
  postCreated,
  postUpdated,
  postDeleted,
  reported,
  commentUpdated,
  commentDeleted,
  requestSent,
  requestAccepted,
  requestRejected,
  requestCancelled,
  friendRemoved,
  userBlocked,
  userUnblocked,
  allNotificationsRead,
  notificationDeleted;

  String text(AppLocalizations l10n) => switch (this) {
    postCreated => l10n.socialMsgPostCreated,
    postUpdated => l10n.socialMsgPostUpdated,
    postDeleted => l10n.socialMsgPostDeleted,
    reported => l10n.socialMsgReported,
    commentUpdated => l10n.socialMsgCommentUpdated,
    commentDeleted => l10n.socialMsgCommentDeleted,
    requestSent => l10n.socialMsgRequestSent,
    requestAccepted => l10n.socialMsgRequestAccepted,
    requestRejected => l10n.socialMsgRequestRejected,
    requestCancelled => l10n.socialMsgRequestCancelled,
    friendRemoved => l10n.socialMsgFriendRemoved,
    userBlocked => l10n.socialMsgUserBlocked,
    userUnblocked => l10n.socialMsgUserUnblocked,
    allNotificationsRead => l10n.socialMsgAllNotificationsRead,
    notificationDeleted => l10n.socialMsgNotificationDeleted,
  };
}

/// Aviso puntual que un bloc emite para que la página lo muestre una vez.
///
/// Los blocs lo emiten y lo limpian justo después, así la página lo recibe
/// una sola vez aunque se repita.
@freezed
sealed class SocialFeedback with _$SocialFeedback {
  const factory SocialFeedback.error(AppError error) = SocialFeedbackError;

  const factory SocialFeedback.message(SocialMessage message) =
      SocialFeedbackMessage;
}
