import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/errors/app_error.dart';
import '../../../extensions/context_extensions.dart';
import '../../../mixins/errors_message_mixin.dart';
import '../feedback/social_feedback.dart';
import '../social_routes.dart';

export '../feedback/social_feedback.dart';

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
