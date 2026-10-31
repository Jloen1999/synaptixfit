import '../gen_l10n/app_localizations.dart';

/// Códigos de autenticación y transversales de negocio.
String? coreErrorMessage(AppLocalizations l10n, String code) => switch (code) {
  'AUTH_INVALID_CREDENTIALS' => l10n.errorAuthInvalidCredentials,
  'AUTH_INVALID_REFRESH_TOKEN' => l10n.errorUnauthorized,
  'AUTH_INVALID_GOOGLE_TOKEN' => l10n.errorAuthGoogleFailed,
  'AUTH_ACCOUNT_DISABLED' => l10n.errorAuthAccountDisabled,
  'AUTH_EMAIL_ALREADY_REGISTERED' => l10n.errorAuthEmailAlreadyRegistered,
  'AUTH_WEAK_PASSWORD' => l10n.errorAuthWeakPassword,
  'AUTH_RESET_TOKEN_INVALID' => l10n.errorAuthResetTokenInvalid,
  'GOOGLE_SIGN_IN_CANCELLED' => l10n.errorAuthGoogleCancelled,
  'GOOGLE_SIGN_IN_FAILED' => l10n.errorAuthGoogleFailed,
  'USER_NOT_FOUND' => l10n.errorNotFound,
  'AI_UNAVAILABLE' => l10n.errorAiUnavailable,
  'AI_QUOTA_EXCEEDED' => l10n.errorAiQuotaExceeded,
  'AI_ATTACHMENT_UNSUPPORTED' => l10n.errorAiAttachmentUnsupported,
  'STORAGE_UNAVAILABLE' => l10n.errorStorageUnavailable,
  _ => null,
};
