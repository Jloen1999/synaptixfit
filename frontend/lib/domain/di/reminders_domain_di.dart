import 'package:get_it/get_it.dart';

import '../use_cases/reminders/cancel_timer_alert_use_case.dart';
import '../use_cases/reminders/schedule_timer_alert_use_case.dart';
import '../use_cases/reminders/clear_reminders_use_case.dart';
import '../use_cases/reminders/get_device_reminders_status_use_case.dart';
import '../use_cases/reminders/mark_reminders_offered_use_case.dart';
import '../use_cases/reminders/set_device_reminders_enabled_use_case.dart';
import '../use_cases/reminders/should_offer_reminders_use_case.dart';
import '../use_cases/reminders/sync_reminders_use_case.dart';
import '../use_cases/reminders/watch_device_reminders_enabled_use_case.dart';
import '../use_cases/reminders/watch_opened_reminders_use_case.dart';

/// Casos de uso de los recordatorios locales del móvil.
void registerRemindersDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<ScheduleTimerAlertUseCaseContract>(
      () => ScheduleTimerAlertUseCase(getIt()),
    )
    ..registerLazySingleton<CancelTimerAlertUseCaseContract>(
      () => CancelTimerAlertUseCase(getIt()),
    )
    ..registerLazySingleton<SyncRemindersUseCaseContract>(
      () => SyncRemindersUseCase(
        scheduler: getIt(),
        settings: getIt(),
        plan: getIt(),
      ),
    )
    ..registerLazySingleton<ClearRemindersUseCaseContract>(
      () => ClearRemindersUseCase(getIt()),
    )
    ..registerLazySingleton<GetDeviceRemindersStatusUseCaseContract>(
      () => GetDeviceRemindersStatusUseCase(
        scheduler: getIt(),
        settings: getIt(),
      ),
    )
    ..registerLazySingleton<ShouldOfferRemindersUseCaseContract>(
      () => ShouldOfferRemindersUseCase(scheduler: getIt(), settings: getIt()),
    )
    ..registerLazySingleton<MarkRemindersOfferedUseCaseContract>(
      () => MarkRemindersOfferedUseCase(getIt()),
    )
    ..registerLazySingleton<SetDeviceRemindersEnabledUseCaseContract>(
      () => SetDeviceRemindersEnabledUseCase(
        scheduler: getIt(),
        settings: getIt(),
      ),
    )
    ..registerLazySingleton<WatchDeviceRemindersEnabledUseCaseContract>(
      () => WatchDeviceRemindersEnabledUseCase(getIt()),
    )
    ..registerLazySingleton<WatchOpenedRemindersUseCaseContract>(
      () => WatchOpenedRemindersUseCase(getIt()),
    );
}
