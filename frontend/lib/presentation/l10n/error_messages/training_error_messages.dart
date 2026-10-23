import '../gen_l10n/app_localizations.dart';

/// Códigos de error del módulo training.
String? trainingErrorMessage(AppLocalizations l10n, String code) =>
    switch (code) {
      'EXERCISE_NOT_FOUND' => l10n.trainingErrorExerciseNotFound,
      'EXERCISE_INACTIVE' => l10n.trainingErrorExerciseInactive,
      'EXERCISE_CATALOG_REFERENCE_INVALID' =>
        l10n.trainingErrorExerciseCatalogReferenceInvalid,
      'ROUTINE_NOT_FOUND' => l10n.trainingErrorRoutineNotFound,
      'ROUTINE_WEEK_NOT_FOUND' => l10n.trainingErrorRoutineWeekNotFound,
      'ROUTINE_DAY_NOT_FOUND' => l10n.trainingErrorRoutineDayNotFound,
      'ROUTINE_EXERCISE_NOT_FOUND' => l10n.trainingErrorRoutineExerciseNotFound,
      'ROUTINE_DAY_DUPLICATED' => l10n.trainingErrorRoutineDayDuplicated,
      'ROUTINE_WEEK_LIMIT' => l10n.trainingErrorRoutineWeekLimit,
      'ROUTINE_HAS_EMPTY_DAYS' => l10n.trainingErrorRoutineHasEmptyDays,
      'ROUTINE_REORDER_MISMATCH' => l10n.trainingErrorRoutineReorderMismatch,
      'SESSION_NOT_FOUND' => l10n.trainingErrorSessionNotFound,
      'SESSION_SET_NOT_FOUND' => l10n.trainingErrorSessionSetNotFound,
      'SESSION_ALREADY_COMPLETED' => l10n.trainingErrorSessionAlreadyCompleted,
      'SESSION_NOT_COMPLETED' => l10n.trainingErrorSessionNotCompleted,
      'SESSION_DAY_MISMATCH' => l10n.trainingErrorSessionDayMismatch,
      'TRAINING_PROFILE_REQUIRED' => l10n.trainingErrorTrainingProfileRequired,
      'TRAINING_NO_COMPATIBLE_EXERCISES' =>
        l10n.trainingErrorTrainingNoCompatibleExercises,
      'TRAINING_PLAN_NOT_FOUND' => l10n.trainingErrorTrainingPlanNotFound,
      'TRAINING_RECOMMENDATION_NOT_FOUND' =>
        l10n.trainingErrorTrainingRecommendationNotFound,
      'TRAINING_RECOMMENDATION_APPLIED' =>
        l10n.trainingErrorTrainingRecommendationApplied,
      _ => null,
    };
