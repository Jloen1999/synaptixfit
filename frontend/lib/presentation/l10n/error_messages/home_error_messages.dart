import '../gen_l10n/app_localizations.dart';

/// Códigos de error del módulo home (`GET /api/v1/dashboard`).
String? homeErrorMessage(AppLocalizations l10n, String code) => switch (code) {
  'INSIGHTS_INVALID_TIME_ZONE' => l10n.homeErrorInvalidTimeZone,
  _ => null,
};
