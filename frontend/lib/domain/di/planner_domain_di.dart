import '../use_cases/planner/create_calendar_feed_use_case.dart';
import '../use_cases/planner/get_calendar_feed_use_case.dart';
import '../use_cases/planner/revoke_calendar_feed_use_case.dart';
import '../use_cases/planner/reschedule_block_to_next_free_slot_use_case.dart';
import 'package:get_it/get_it.dart';

import '../use_cases/planner/clear_active_focus_timer_use_case.dart';
import '../use_cases/planner/load_active_focus_timer_use_case.dart';
import '../use_cases/planner/save_active_focus_timer_use_case.dart';

import '../use_cases/planner/get_week_blocks_use_case.dart';
import '../use_cases/planner/create_block_use_case.dart';
import '../use_cases/planner/update_block_use_case.dart';
import '../use_cases/planner/reschedule_block_use_case.dart';
import '../use_cases/planner/delete_block_use_case.dart';
import '../use_cases/planner/set_block_completion_use_case.dart';
import '../use_cases/planner/distribute_routine_use_case.dart';
import '../use_cases/planner/get_week_conflicts_use_case.dart';
import '../use_cases/planner/save_week_plan_use_case.dart';
import '../use_cases/planner/get_weekly_load_use_case.dart';
import '../use_cases/planner/update_weekly_wellbeing_use_case.dart';
import '../use_cases/planner/sync_weekly_load_use_case.dart';
import '../use_cases/planner/get_week_balance_use_case.dart';
import '../use_cases/planner/get_timeline_use_case.dart';
import '../use_cases/planner/suggest_week_plan_use_case.dart';
import '../use_cases/planner/scan_schedule_use_case.dart';
import '../use_cases/planner/save_semester_dates_use_case.dart';
import '../use_cases/planner/import_general_calendar_use_case.dart';
import '../use_cases/planner/log_past_activity_use_case.dart';
import '../use_cases/planner/log_past_study_use_case.dart';
import '../use_cases/planner/import_ics_use_case.dart';
import '../use_cases/planner/export_ics_use_case.dart';
import '../use_cases/planner/get_planner_subjects_use_case.dart';
import '../use_cases/planner/get_planner_routines_use_case.dart';
import '../use_cases/planner/get_planner_challenges_use_case.dart';
import '../use_cases/planner/get_deadlines_use_case.dart';
import '../use_cases/planner/create_deadline_use_case.dart';
import '../use_cases/planner/update_deadline_use_case.dart';
import '../use_cases/planner/delete_deadline_use_case.dart';
import '../use_cases/planner/set_deadline_completion_use_case.dart';
import '../use_cases/planner/record_focus_session_use_case.dart';
import '../use_cases/planner/get_focus_plan_use_case.dart';
import '../use_cases/planner/get_focus_stats_use_case.dart';

/// Casos de uso del módulo planner.
void registerPlannerDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<LoadActiveFocusTimerUseCaseContract>(
      () => LoadActiveFocusTimerUseCase(getIt()),
    )
    ..registerLazySingleton<SaveActiveFocusTimerUseCaseContract>(
      () => SaveActiveFocusTimerUseCase(getIt()),
    )
    ..registerLazySingleton<ClearActiveFocusTimerUseCaseContract>(
      () => ClearActiveFocusTimerUseCase(getIt()),
    )
    ..registerLazySingleton<GetWeekBlocksUseCaseContract>(
      () => GetWeekBlocksUseCase(getIt()),
    )
    ..registerLazySingleton<CreateBlockUseCaseContract>(
      () => CreateBlockUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateBlockUseCaseContract>(
      () => UpdateBlockUseCase(getIt()),
    )
    ..registerLazySingleton<RescheduleBlockUseCaseContract>(
      () => RescheduleBlockUseCase(getIt()),
    )
    ..registerLazySingleton<RescheduleBlockToNextFreeSlotUseCaseContract>(
      () => RescheduleBlockToNextFreeSlotUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteBlockUseCaseContract>(
      () => DeleteBlockUseCase(getIt()),
    )
    ..registerLazySingleton<SetBlockCompletionUseCaseContract>(
      () => SetBlockCompletionUseCase(getIt()),
    )
    ..registerLazySingleton<DistributeRoutineUseCaseContract>(
      () => DistributeRoutineUseCase(getIt()),
    )
    ..registerLazySingleton<GetWeekConflictsUseCaseContract>(
      () => GetWeekConflictsUseCase(getIt()),
    )
    ..registerLazySingleton<SaveWeekPlanUseCaseContract>(
      () => SaveWeekPlanUseCase(getIt()),
    )
    ..registerLazySingleton<GetWeeklyLoadUseCaseContract>(
      () => GetWeeklyLoadUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateWeeklyWellbeingUseCaseContract>(
      () => UpdateWeeklyWellbeingUseCase(getIt()),
    )
    ..registerLazySingleton<SyncWeeklyLoadUseCaseContract>(
      () => SyncWeeklyLoadUseCase(getIt()),
    )
    ..registerLazySingleton<GetWeekBalanceUseCaseContract>(
      () => GetWeekBalanceUseCase(getIt()),
    )
    ..registerLazySingleton<GetTimelineUseCaseContract>(
      () => GetTimelineUseCase(getIt()),
    )
    ..registerLazySingleton<SuggestWeekPlanUseCaseContract>(
      () => SuggestWeekPlanUseCase(getIt()),
    )
    ..registerLazySingleton<ScanScheduleUseCaseContract>(
      () => ScanScheduleUseCase(getIt()),
    )
    ..registerLazySingleton<SaveSemesterDatesUseCaseContract>(
      () => SaveSemesterDatesUseCase(getIt()),
    )
    ..registerLazySingleton<GetCalendarFeedUseCaseContract>(
      () => GetCalendarFeedUseCase(getIt()),
    )
    ..registerLazySingleton<CreateCalendarFeedUseCaseContract>(
      () => CreateCalendarFeedUseCase(getIt()),
    )
    ..registerLazySingleton<RevokeCalendarFeedUseCaseContract>(
      () => RevokeCalendarFeedUseCase(getIt()),
    )
    ..registerLazySingleton<LogPastStudyUseCaseContract>(
      () => LogPastStudyUseCase(getIt()),
    )
    ..registerLazySingleton<LogPastActivityUseCaseContract>(
      () => LogPastActivityUseCase(getIt()),
    )
    ..registerLazySingleton<ImportGeneralCalendarUseCaseContract>(
      () => ImportGeneralCalendarUseCase(getIt()),
    )
    ..registerLazySingleton<ImportIcsUseCaseContract>(
      () => ImportIcsUseCase(getIt()),
    )
    ..registerLazySingleton<ExportIcsUseCaseContract>(
      () => ExportIcsUseCase(getIt()),
    )
    ..registerLazySingleton<GetPlannerSubjectsUseCaseContract>(
      () => GetPlannerSubjectsUseCase(getIt()),
    )
    ..registerLazySingleton<GetPlannerRoutinesUseCaseContract>(
      () => GetPlannerRoutinesUseCase(getIt()),
    )
    ..registerLazySingleton<GetPlannerChallengesUseCaseContract>(
      () => GetPlannerChallengesUseCase(getIt()),
    )
    ..registerLazySingleton<GetDeadlinesUseCaseContract>(
      () => GetDeadlinesUseCase(getIt()),
    )
    ..registerLazySingleton<CreateDeadlineUseCaseContract>(
      () => CreateDeadlineUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateDeadlineUseCaseContract>(
      () => UpdateDeadlineUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteDeadlineUseCaseContract>(
      () => DeleteDeadlineUseCase(getIt()),
    )
    ..registerLazySingleton<SetDeadlineCompletionUseCaseContract>(
      () => SetDeadlineCompletionUseCase(getIt()),
    )
    ..registerLazySingleton<RecordFocusSessionUseCaseContract>(
      () => RecordFocusSessionUseCase(getIt()),
    )
    ..registerLazySingleton<GetFocusPlanUseCaseContract>(
      () => GetFocusPlanUseCase(getIt()),
    )
    ..registerLazySingleton<GetFocusStatsUseCaseContract>(
      () => GetFocusStatsUseCase(getIt()),
    );
}
