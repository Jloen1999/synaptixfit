import '../gen_l10n/app_localizations.dart';

/// Códigos de error del módulo admin (y del catálogo de ejercicios que usa).
String? adminErrorMessage(AppLocalizations l10n, String code) => switch (code) {
  'ADMIN_USER_NOT_FOUND' => l10n.adminErrorUserNotFound,
  'ADMIN_CANNOT_TARGET_SELF' => l10n.adminErrorCannotTargetSelf,
  'ADMIN_EMAIL_ALREADY_IN_USE' => l10n.adminErrorEmailInUse,
  'ADMIN_USER_DELETED' => l10n.adminErrorUserDeleted,
  'ADMIN_INVALID_DATE_RANGE' => l10n.adminErrorInvalidDateRange,
  'EXERCISE_NOT_FOUND' => l10n.adminErrorExerciseNotFound,
  'EXERCISE_INACTIVE' => l10n.adminErrorExerciseInactive,
  'EXERCISE_CATALOG_REFERENCE_INVALID' => l10n.adminErrorCatalogReference,
  _ => null,
};
