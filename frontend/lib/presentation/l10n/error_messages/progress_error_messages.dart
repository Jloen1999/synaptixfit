import '../gen_l10n/app_localizations.dart';

/// Códigos de error del módulo progress.
String? progressErrorMessage(AppLocalizations l10n, String code) =>
    switch (code) {
      'BADGE_NOT_FOUND' => l10n.progressErrorBadgeNotFound,
      'STREAK_INVALID_ZONE' ||
      'INSIGHTS_INVALID_TIME_ZONE' => l10n.progressErrorInvalidZone,
      'ANALYTICS_INVALID_PERIOD' => l10n.progressErrorInvalidPeriod,
      'ANALYTICS_INVALID_METRIC' => l10n.progressErrorInvalidMetric,
      _ => null,
    };
