import 'package:flutter/widgets.dart';

import '../../app/validators/validators.dart';
import 'context_extensions.dart';

extension ValidationFailureText on ValidationFailure {
  String text(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      ValidationFailure.required => l10n.validationRequired,
      ValidationFailure.invalidEmail => l10n.validationInvalidEmail,
      ValidationFailure.weakPassword => l10n.validationWeakPassword,
      ValidationFailure.tooShort => l10n.validationTooShort,
    };
  }
}
