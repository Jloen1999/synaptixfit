import '../gen_l10n/app_localizations.dart';

/// Códigos de error del módulo challenges (CHALLENGE_*, MILESTONE_*).
String? challengesErrorMessage(AppLocalizations l10n, String code) =>
    switch (code) {
      'CHALLENGE_NOT_FOUND' => l10n.challengesErrorNotFound,
      'CHALLENGE_EXPIRED' => l10n.challengesErrorExpired,
      'MILESTONE_NOT_FOUND' => l10n.challengesErrorMilestoneNotFound,
      'CHALLENGE_SUBJECT_NOT_FOUND' => l10n.challengesErrorSubjectNotFound,
      'CHALLENGE_LINK_NOT_FOUND' => l10n.challengesErrorLinkNotFound,
      'MILESTONE_ATTACHMENT_NOT_FOUND' =>
        l10n.challengesErrorAttachmentNotFound,
      'CHALLENGE_INVALID_DATES' => l10n.challengesErrorInvalidDates,
      'CHALLENGE_TYPE_OUTSIDE_FOCUS' => l10n.challengesErrorTypeOutsideFocus,
      'MILESTONE_ATTACHMENT_CONFLICT' => l10n.challengesErrorAttachmentConflict,
      'CHALLENGE_TOO_MANY_MILESTONES' => l10n.challengesErrorTooManyMilestones,
      'CHALLENGE_NOT_STARTED' => l10n.challengesErrorNotStarted,
      'CHALLENGE_LINKED' => l10n.challengesErrorLinked,
      'MILESTONE_LINKED' => l10n.challengesErrorMilestoneLinked,
      'CHALLENGE_LINK_OUTSIDE_PERIOD' => l10n.challengesErrorLinkOutsidePeriod,
      'MILESTONE_DEPENDENCY_INVALID' => l10n.challengesErrorDependencyInvalid,
      'MILESTONE_LOCKED' => l10n.challengesErrorMilestoneLocked,
      'MILESTONE_ORDER_INVALID' => l10n.challengesErrorOrderInvalid,
      'CHALLENGE_PROGRESS_MILESTONE_REQUIRED' =>
        l10n.challengesErrorProgressMilestoneRequired,
      'MILESTONE_ALREADY_COMPLETED' =>
        l10n.challengesErrorMilestoneAlreadyCompleted,
      'CHALLENGE_ALREADY_COMPLETED' => l10n.challengesErrorAlreadyCompleted,
      _ => null,
    };
