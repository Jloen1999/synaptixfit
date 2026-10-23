import '../gen_l10n/app_localizations.dart';

/// Códigos de error del módulo profile (perfil, catálogo académico y RGPD).
String? profileErrorMessage(AppLocalizations l10n, String code) =>
    switch (code) {
      'PROFILE_WELLNESS_NOT_FOUND' => l10n.profileErrorWellnessNotFound,
      'PROFILE_ACADEMIC_NOT_FOUND' => l10n.profileErrorAcademicNotFound,
      'PROFILE_INVALID_CLASS_DATES' => l10n.profileErrorInvalidClassDates,
      'PROFILE_ONBOARDING_WELLNESS_REQUIRED' =>
        l10n.profileErrorOnboardingWellnessRequired,
      'CATALOG_UNIVERSITY_NOT_FOUND' => l10n.profileErrorUniversityNotFound,
      'CATALOG_CENTER_NOT_FOUND' => l10n.profileErrorCenterNotFound,
      'CATALOG_DEGREE_NOT_FOUND' => l10n.profileErrorDegreeNotFound,
      'CATALOG_SUBJECT_NOT_FOUND' => l10n.profileErrorCatalogSubjectNotFound,
      'GDPR_CONFIRMATION_REQUIRED' => l10n.profileErrorGdprConfirmationRequired,
      'GDPR_PASSWORD_MISMATCH' => l10n.profileErrorGdprPasswordMismatch,
      'GDPR_LAST_ADMIN' => l10n.profileErrorGdprLastAdmin,
      // Lo emite el módulo de notificaciones, pero se muestra en Ajustes.
      'NOTIFICATION_INVALID_QUIET_HOURS' => l10n.profileErrorQuietHours,
      _ => null,
    };
