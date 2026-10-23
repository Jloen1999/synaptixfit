import 'package:flutter/widgets.dart';

import '../../domain/errors/app_error.dart';
import '../extensions/context_extensions.dart';
import '../l10n/error_messages/error_messages.dart';

/// Convierte un [AppError] en el texto del `.arb`. Nunca muestra el `detail` del servidor.
mixin ErrorsMessageMixin {
  String errorMessage(BuildContext context, AppError error) {
    final l10n = context.localizations;
    return switch (error) {
      ServerError() => l10n.errorServer,
      ValidationError() => l10n.errorValidation,
      UnauthorizedError() => l10n.errorUnauthorized,
      ForbiddenError() => l10n.errorForbidden,
      NotFoundError() => l10n.errorNotFound,
      ConflictError() => l10n.errorConflict,
      NetworkError() => l10n.errorNetwork,
      BusinessError(:final code) =>
        businessErrorMessage(l10n, code) ?? l10n.errorUnknown,
      UnknownAppError() => l10n.errorUnknown,
    };
  }
}
