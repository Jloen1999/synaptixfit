import 'package:get_it/get_it.dart';

import '../use_cases/training/add_routine_day_use_case.dart';
import '../use_cases/training/add_routine_exercise_use_case.dart';
import '../use_cases/training/add_routine_week_use_case.dart';
import '../use_cases/training/apply_recommendation_use_case.dart';
import '../use_cases/training/cancel_session_use_case.dart';
import '../use_cases/training/change_routine_status_use_case.dart';
import '../use_cases/training/clone_routine_use_case.dart';
import '../use_cases/training/correct_session_use_case.dart';
import '../use_cases/training/create_routine_use_case.dart';
import '../use_cases/training/delete_routine_day_use_case.dart';
import '../use_cases/training/delete_routine_use_case.dart';
import '../use_cases/training/delete_routine_week_use_case.dart';
import '../use_cases/training/delete_session_use_case.dart';
import '../use_cases/training/delete_set_use_case.dart';
import '../use_cases/training/pause_session_use_case.dart';
import '../use_cases/training/resume_session_use_case.dart';
import '../use_cases/training/delete_weekly_plan_use_case.dart';
import '../use_cases/training/discard_recommendation_use_case.dart';
import '../use_cases/training/duplicate_routine_use_case.dart';
import '../use_cases/training/finish_session_use_case.dart';
import '../use_cases/training/generate_routine_use_case.dart';
import '../use_cases/training/get_body_weight_use_case.dart';
import '../use_cases/training/get_check_ins_use_case.dart';
import '../use_cases/training/get_community_routines_use_case.dart';
import '../use_cases/training/get_exercise_alternatives_use_case.dart';
import '../use_cases/training/get_exercise_filters_use_case.dart';
import '../use_cases/training/get_exercise_use_case.dart';
import '../use_cases/training/get_last_performance_use_case.dart';
import '../use_cases/training/get_load_suggestions_use_case.dart';
import '../use_cases/training/get_my_routines_use_case.dart';
import '../use_cases/training/get_open_sessions_use_case.dart';
import '../use_cases/training/get_pending_day_use_case.dart';
import '../use_cases/training/get_personal_records_use_case.dart';
import '../use_cases/training/get_recommendations_use_case.dart';
import '../use_cases/training/get_routine_use_case.dart';
import '../use_cases/training/get_session_adaptation_use_case.dart';
import '../use_cases/training/get_session_bookends_use_case.dart';
import '../use_cases/training/get_session_clock_intro_hidden_use_case.dart';
import '../use_cases/training/get_session_highlights_use_case.dart';
import '../use_cases/training/get_session_history_use_case.dart';
import '../use_cases/training/get_session_use_case.dart';
import '../use_cases/training/get_sessions_use_case.dart';
import '../use_cases/training/get_today_check_in_use_case.dart';
import '../use_cases/training/get_weekly_plan_use_case.dart';
import '../use_cases/training/get_weekly_plans_use_case.dart';
import '../use_cases/training/hide_session_clock_intro_use_case.dart';
import '../use_cases/training/load_pending_sets_use_case.dart';
import '../use_cases/training/log_past_session_use_case.dart';
import '../use_cases/training/record_set_use_case.dart';
import '../use_cases/training/refine_routine_use_case.dart';
import '../use_cases/training/remove_routine_exercise_use_case.dart';
import '../use_cases/training/replace_routine_exercise_use_case.dart';
import '../use_cases/training/rename_routine_day_use_case.dart';
import '../use_cases/training/reorder_routine_exercises_use_case.dart';
import '../use_cases/training/restart_routine_use_case.dart';
import '../use_cases/training/save_pending_sets_use_case.dart';
import '../use_cases/training/save_weekly_plan_use_case.dart';
import '../use_cases/training/search_exercises_use_case.dart';
import '../use_cases/training/skip_routine_day_use_case.dart';
import '../use_cases/training/start_session_use_case.dart';
import '../use_cases/training/submit_check_in_use_case.dart';
import '../use_cases/training/unmark_session_use_case.dart';
import '../use_cases/training/unskip_routine_day_use_case.dart';
import '../use_cases/training/update_routine_exercise_use_case.dart';
import '../use_cases/training/update_routine_use_case.dart';
import '../use_cases/training/update_routine_week_use_case.dart';

/// Casos de uso del módulo training.
void registerTrainingDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<SearchExercisesUseCaseContract>(
      () => SearchExercisesUseCase(getIt()),
    )
    ..registerLazySingleton<GetExerciseUseCaseContract>(
      () => GetExerciseUseCase(getIt()),
    )
    ..registerLazySingleton<GetExerciseFiltersUseCaseContract>(
      () => GetExerciseFiltersUseCase(getIt()),
    )
    ..registerLazySingleton<GetMyRoutinesUseCaseContract>(
      () => GetMyRoutinesUseCase(getIt()),
    )
    ..registerLazySingleton<GetCommunityRoutinesUseCaseContract>(
      () => GetCommunityRoutinesUseCase(getIt()),
    )
    ..registerLazySingleton<GetRoutineUseCaseContract>(
      () => GetRoutineUseCase(getIt()),
    )
    ..registerLazySingleton<CreateRoutineUseCaseContract>(
      () => CreateRoutineUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateRoutineUseCaseContract>(
      () => UpdateRoutineUseCase(getIt()),
    )
    ..registerLazySingleton<ChangeRoutineStatusUseCaseContract>(
      () => ChangeRoutineStatusUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteRoutineUseCaseContract>(
      () => DeleteRoutineUseCase(getIt()),
    )
    ..registerLazySingleton<DuplicateRoutineUseCaseContract>(
      () => DuplicateRoutineUseCase(getIt()),
    )
    ..registerLazySingleton<CloneRoutineUseCaseContract>(
      () => CloneRoutineUseCase(getIt()),
    )
    ..registerLazySingleton<AddRoutineWeekUseCaseContract>(
      () => AddRoutineWeekUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateRoutineWeekUseCaseContract>(
      () => UpdateRoutineWeekUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteRoutineWeekUseCaseContract>(
      () => DeleteRoutineWeekUseCase(getIt()),
    )
    ..registerLazySingleton<AddRoutineDayUseCaseContract>(
      () => AddRoutineDayUseCase(getIt()),
    )
    ..registerLazySingleton<RenameRoutineDayUseCaseContract>(
      () => RenameRoutineDayUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteRoutineDayUseCaseContract>(
      () => DeleteRoutineDayUseCase(getIt()),
    )
    ..registerLazySingleton<AddRoutineExerciseUseCaseContract>(
      () => AddRoutineExerciseUseCase(getIt()),
    )
    ..registerLazySingleton<ReorderRoutineExercisesUseCaseContract>(
      () => ReorderRoutineExercisesUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateRoutineExerciseUseCaseContract>(
      () => UpdateRoutineExerciseUseCase(getIt()),
    )
    ..registerLazySingleton<RemoveRoutineExerciseUseCaseContract>(
      () => RemoveRoutineExerciseUseCase(getIt()),
    )
    ..registerLazySingleton<ReplaceRoutineExerciseUseCaseContract>(
      () => ReplaceRoutineExerciseUseCase(getIt()),
    )
    ..registerLazySingleton<GenerateRoutineUseCaseContract>(
      () => GenerateRoutineUseCase(getIt()),
    )
    ..registerLazySingleton<RefineRoutineUseCaseContract>(
      () => RefineRoutineUseCase(getIt()),
    )
    ..registerLazySingleton<GetPendingDayUseCaseContract>(
      () => GetPendingDayUseCase(getIt()),
    )
    ..registerLazySingleton<StartSessionUseCaseContract>(
      () => StartSessionUseCase(getIt()),
    )
    ..registerLazySingleton<GetSessionUseCaseContract>(
      () => GetSessionUseCase(getIt()),
    )
    ..registerLazySingleton<GetLoadSuggestionsUseCaseContract>(
      () => GetLoadSuggestionsUseCase(getIt()),
    )
    ..registerLazySingleton<GetSessionAdaptationUseCaseContract>(
      () => GetSessionAdaptationUseCase(getIt()),
    )
    ..registerLazySingleton<GetSessionsUseCaseContract>(
      () => GetSessionsUseCase(getIt()),
    )
    ..registerLazySingleton<GetSessionHistoryUseCaseContract>(
      () => GetSessionHistoryUseCase(getIt()),
    )
    ..registerLazySingleton<GetLastPerformanceUseCaseContract>(
      () => GetLastPerformanceUseCase(getIt()),
    )
    ..registerLazySingleton<GetSessionHighlightsUseCaseContract>(
      () => GetSessionHighlightsUseCase(getIt()),
    )
    ..registerLazySingleton<GetExerciseAlternativesUseCaseContract>(
      () => GetExerciseAlternativesUseCase(getIt()),
    )
    ..registerLazySingleton<GetSessionBookendsUseCaseContract>(
      () => GetSessionBookendsUseCase(getIt()),
    )
    ..registerLazySingleton<GetPersonalRecordsUseCaseContract>(
      () => GetPersonalRecordsUseCase(getIt()),
    )
    ..registerLazySingleton<LoadPendingSetsUseCaseContract>(
      () => LoadPendingSetsUseCase(getIt()),
    )
    ..registerLazySingleton<SavePendingSetsUseCaseContract>(
      () => SavePendingSetsUseCase(getIt()),
    )
    ..registerLazySingleton<RecordSetUseCaseContract>(
      () => RecordSetUseCase(getIt()),
    )
    ..registerLazySingleton<GetSessionClockIntroHiddenUseCaseContract>(
      () => GetSessionClockIntroHiddenUseCase(getIt()),
    )
    ..registerLazySingleton<HideSessionClockIntroUseCaseContract>(
      () => HideSessionClockIntroUseCase(getIt()),
    )
    ..registerLazySingleton<PauseSessionUseCaseContract>(
      () => PauseSessionUseCase(getIt()),
    )
    ..registerLazySingleton<ResumeSessionUseCaseContract>(
      () => ResumeSessionUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteSetUseCaseContract>(
      () => DeleteSetUseCase(getIt()),
    )
    ..registerLazySingleton<FinishSessionUseCaseContract>(
      () => FinishSessionUseCase(getIt()),
    )
    ..registerLazySingleton<UnmarkSessionUseCaseContract>(
      () => UnmarkSessionUseCase(getIt()),
    )
    ..registerLazySingleton<CancelSessionUseCaseContract>(
      () => CancelSessionUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteSessionUseCaseContract>(
      () => DeleteSessionUseCase(getIt()),
    )
    ..registerLazySingleton<GetOpenSessionsUseCaseContract>(
      () => GetOpenSessionsUseCase(getIt()),
    )
    ..registerLazySingleton<CorrectSessionUseCaseContract>(
      () => CorrectSessionUseCase(getIt()),
    )
    ..registerLazySingleton<LogPastSessionUseCaseContract>(
      () => LogPastSessionUseCase(getIt()),
    )
    ..registerLazySingleton<SkipRoutineDayUseCaseContract>(
      () => SkipRoutineDayUseCase(getIt()),
    )
    ..registerLazySingleton<UnskipRoutineDayUseCaseContract>(
      () => UnskipRoutineDayUseCase(getIt()),
    )
    ..registerLazySingleton<RestartRoutineUseCaseContract>(
      () => RestartRoutineUseCase(getIt()),
    )
    ..registerLazySingleton<GetTodayCheckInUseCaseContract>(
      () => GetTodayCheckInUseCase(getIt()),
    )
    ..registerLazySingleton<SubmitCheckInUseCaseContract>(
      () => SubmitCheckInUseCase(getIt()),
    )
    ..registerLazySingleton<GetCheckInsUseCaseContract>(
      () => GetCheckInsUseCase(getIt()),
    )
    ..registerLazySingleton<GetWeeklyPlanUseCaseContract>(
      () => GetWeeklyPlanUseCase(getIt()),
    )
    ..registerLazySingleton<SaveWeeklyPlanUseCaseContract>(
      () => SaveWeeklyPlanUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteWeeklyPlanUseCaseContract>(
      () => DeleteWeeklyPlanUseCase(getIt()),
    )
    ..registerLazySingleton<GetWeeklyPlansUseCaseContract>(
      () => GetWeeklyPlansUseCase(getIt()),
    )
    ..registerLazySingleton<GetRecommendationsUseCaseContract>(
      () => GetRecommendationsUseCase(getIt()),
    )
    ..registerLazySingleton<ApplyRecommendationUseCaseContract>(
      () => ApplyRecommendationUseCase(getIt()),
    )
    ..registerLazySingleton<DiscardRecommendationUseCaseContract>(
      () => DiscardRecommendationUseCase(getIt()),
    )
    ..registerLazySingleton<GetBodyWeightUseCaseContract>(
      () => GetBodyWeightUseCase(getIt()),
    );
}
