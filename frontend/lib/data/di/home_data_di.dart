import '../repository/setup_reminder_repository.dart';
import '../local_data_source/setup_reminder_storage.dart';
import '../../domain/repositories/setup_reminder_repository_contract.dart';
import 'package:get_it/get_it.dart';

import '../../domain/repositories/home_repository_contract.dart';
import '../remote_data_source/home/home_remote_data_source.dart';
import '../repository/home_repository.dart';

/// Data sources y repositorios del módulo home.
void registerHomeData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => HomeRemoteDataSource(getIt()))
    ..registerLazySingleton<HomeRepositoryContract>(
      () => HomeRepository(getIt()),
    )
    ..registerLazySingleton<SetupReminderRepositoryContract>(
      () => SetupReminderRepository(SharedPrefsSetupReminderStorage()),
    );
}
