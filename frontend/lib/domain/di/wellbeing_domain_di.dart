import 'package:get_it/get_it.dart';

import '../use_cases/reminders/change_reminder_options_use_case.dart';
import '../use_cases/reminders/get_reminder_options_use_case.dart';
import '../use_cases/training/change_cycle_tracking_use_case.dart';
import '../use_cases/training/delete_cycle_day_use_case.dart';
import '../use_cases/training/delete_cycle_history_use_case.dart';
import '../use_cases/training/get_cycle_overview_use_case.dart';
import '../use_cases/training/get_today_adaptation_use_case.dart';
import '../use_cases/training/list_cycle_days_use_case.dart';
import '../use_cases/training/list_sport_activities_use_case.dart';
import '../use_cases/training/log_cycle_day_use_case.dart';
import '../use_cases/training/submit_quick_check_in_use_case.dart';

/// Casos de uso de bienestar (ADR 0033).
void registerWellbeingDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<GetCycleOverviewUseCaseContract>(
      () => GetCycleOverviewUseCase(getIt()),
    )
    ..registerLazySingleton<ChangeCycleTrackingUseCaseContract>(
      () => ChangeCycleTrackingUseCase(getIt()),
    )
    ..registerLazySingleton<LogCycleDayUseCaseContract>(
      () => LogCycleDayUseCase(getIt()),
    )
    ..registerLazySingleton<ListCycleDaysUseCaseContract>(
      () => ListCycleDaysUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteCycleDayUseCaseContract>(
      () => DeleteCycleDayUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteCycleHistoryUseCaseContract>(
      () => DeleteCycleHistoryUseCase(getIt()),
    )
    ..registerLazySingleton<GetTodayAdaptationUseCaseContract>(
      () => GetTodayAdaptationUseCase(getIt()),
    )
    ..registerLazySingleton<SubmitQuickCheckInUseCaseContract>(
      () => SubmitQuickCheckInUseCase(getIt()),
    )
    ..registerLazySingleton<ListSportActivitiesUseCaseContract>(
      () => ListSportActivitiesUseCase(getIt()),
    )
    ..registerLazySingleton<GetReminderOptionsUseCaseContract>(
      () => GetReminderOptionsUseCase(getIt()),
    )
    ..registerLazySingleton<ChangeReminderOptionsUseCaseContract>(
      () => ChangeReminderOptionsUseCase(getIt()),
    );
}
