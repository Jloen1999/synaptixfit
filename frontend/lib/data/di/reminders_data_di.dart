import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../domain/repositories/reminder_plan_repository_contract.dart';
import '../../domain/repositories/reminder_scheduler_repository_contract.dart';
import '../../domain/repositories/reminder_settings_repository_contract.dart';
import '../local_data_source/local_reminder_scheduler.dart';
import '../local_data_source/reminder_settings_storage.dart';
import '../remote_data_source/reminders/reminder_plan_remote_data_source.dart';
import '../repository/reminder_plan_repository.dart';
import '../repository/reminder_scheduler_repository.dart';
import '../repository/reminder_settings_repository.dart';

/// Recordatorios locales: plugin de notificaciones en Android e iOS y una
/// versión vacía en web y escritorio (donde el plugin no programa avisos), y
/// el plan de avisos que decide el servidor.
void registerRemindersData(GetIt getIt) {
  final mobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  getIt
    ..registerLazySingleton<LocalReminderScheduler>(
      () => mobile
          ? NotificationsReminderScheduler()
          : const NoopReminderScheduler(),
    )
    ..registerLazySingleton<ReminderSettingsStorage>(
      SharedPrefsReminderSettingsStorage.new,
    )
    ..registerLazySingleton<ReminderSchedulerRepositoryContract>(
      () => ReminderSchedulerRepository(getIt()),
    )
    ..registerLazySingleton<ReminderSettingsRepositoryContract>(
      () => ReminderSettingsRepository(getIt()),
    )
    ..registerLazySingleton(() => ReminderPlanRemoteDataSource(getIt()))
    ..registerLazySingleton<ReminderPlanRepositoryContract>(
      () => ReminderPlanRepository(getIt()),
    );
}
