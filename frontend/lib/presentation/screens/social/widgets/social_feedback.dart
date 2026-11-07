import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/errors/app_error.dart';
import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../mixins/errors_message_mixin.dart';
import '../social_routes.dart';

part 'social_feedback.freezed.dart';

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

class _ErrorText with ErrorsMessageMixin {
  const _ErrorText();
}

/// Texto traducido de un [AppError] (nunca el `detail` del servidor).
String socialErrorText(BuildContext context, AppError error) =>
    const _ErrorText().errorMessage(context, error);

/// Muestra el aviso en un SnackBar. Bloquear dice dónde se deshace y lleva
/// allí con «Ver» (salvo [inFriends]: ya se está en Amigos).
void showSocialFeedback(
  BuildContext context,
  SocialFeedback feedback, {
  bool inFriends = false,
}) {
  if (feedback case SocialFeedbackMessage(
    message: SocialMessage.userBlocked,
  ) when !inFriends) {
    context.showActionSnack(
      context.localizations.socialMsgUserBlocked,
      actionLabel: context.localizations.commonView,
      onAction: () => context.push(SocialPaths.blocked),
    );
    return;
  }
  context.showSnack(switch (feedback) {
    SocialFeedbackError(:final error) => socialErrorText(context, error),
    SocialFeedbackMessage(:final message) => message.text(
      context.localizations,
    ),
  });
}
