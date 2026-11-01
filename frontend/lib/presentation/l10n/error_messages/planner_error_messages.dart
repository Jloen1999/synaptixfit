import '../gen_l10n/app_localizations.dart';

/// Códigos de error del módulo planner.
String? plannerErrorMessage(
  AppLocalizations l10n,
  String code,
) => switch (code) {
  'BLOCK_NOT_FOUND' => l10n.plannerErrorBlockNotFound,
  'BLOCK_IN_PAST' => l10n.plannerErrorBlockInPast,
  'BLOCK_IN_FUTURE' => l10n.plannerErrorBlockInFuture,
  'BLOCK_NO_FREE_SLOT' => l10n.plannerErrorBlockNoFreeSlot,
  'BLOCK_LOCKED' => l10n.plannerErrorBlockLocked,
  'BLOCK_COMPLETED_LOCKED' => l10n.plannerErrorBlockCompletedLocked,
  'BLOCK_ROUTINE_LINKED' => l10n.plannerErrorBlockRoutineLinked,
  'BLOCK_INVALID_TIME_RANGE' => l10n.plannerErrorBlockInvalidTimeRange,
  'DEADLINE_NOT_FOUND' => l10n.plannerErrorDeadlineNotFound,
  'PLAN_NOT_FOUND' => l10n.plannerErrorPlanNotFound,
  'PLANNER_SUBJECT_NOT_FOUND' => l10n.plannerErrorSubjectNotFound,
  'PLANNER_ROUTINE_NOT_FOUND' => l10n.plannerErrorRoutineNotFound,
  'PLANNER_CHALLENGE_NOT_FOUND' => l10n.plannerErrorChallengeNotFound,
  'BLOCK_OUTSIDE_CHALLENGE_PERIOD' => l10n.plannerErrorBlockOutsideChallenge,
  'PLANNER_ROUTINE_EMPTY' => l10n.plannerErrorRoutineEmpty,
  'PLANNER_RANGE_TOO_LARGE' => l10n.plannerErrorRangeTooLarge,
  'PLANNER_ICS_URL_MISSING' => l10n.plannerErrorIcsUrlMissing,
  'PLANNER_PAST_ACTIVITY_OUT_OF_RANGE' =>
    l10n.plannerErrorPastActivityOutOfRange,
  'PLANNER_PAST_ACTIVITY_TYPE_NOT_ALLOWED' => l10n.plannerErrorPastActivityType,
  'PLANNER_CALENDAR_FEED_NOT_FOUND' => l10n.plannerErrorCalendarFeedNotFound,
  'PLANNER_ICS_URL_INVALID' => l10n.plannerErrorIcsUrlInvalid,
  'PLANNER_ICS_UNAVAILABLE' => l10n.plannerErrorIcsUnavailable,
  'SCHEDULE_SEMESTER_DATES_MISSING' => l10n.plannerErrorSemesterDatesMissing,
  'SCHEDULE_NOTHING_FOUND' => l10n.plannerErrorScheduleNothingFound,
  'SCHEDULE_UNSUPPORTED_FILE' => l10n.plannerErrorScheduleUnsupportedFile,
  'SCHEDULE_FILE_TOO_LARGE' => l10n.plannerErrorScheduleFileTooLarge,
  _ => null,
};
