import '../gen_l10n/app_localizations.dart';
import 'core_error_messages.dart';
import 'home_error_messages.dart';
import 'academic_error_messages.dart';
import 'training_error_messages.dart';
import 'challenges_error_messages.dart';
import 'progress_error_messages.dart';
import 'profile_error_messages.dart';
import 'planner_error_messages.dart';
import 'social_error_messages.dart';
import 'admin_error_messages.dart';

/// Traduce un `code` de negocio a texto. Cada módulo resuelve sus propios códigos
/// en `<modulo>_error_messages.dart` y devuelve `null` si el código no es suyo.
String? businessErrorMessage(AppLocalizations l10n, String code) {
  for (final resolve in <String? Function(AppLocalizations, String)>[
    coreErrorMessage,
    homeErrorMessage,
    academicErrorMessage,
    trainingErrorMessage,
    challengesErrorMessage,
    progressErrorMessage,
    profileErrorMessage,
    plannerErrorMessage,
    socialErrorMessage,
    adminErrorMessage,
  ]) {
    final message = resolve(l10n, code);
    if (message != null) return message;
  }
  return null;
}
