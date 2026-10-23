import 'package:get_it/get_it.dart';

import '../../domain/repositories/analytics_repository_contract.dart';
import '../../domain/repositories/badge_repository_contract.dart';
import '../../domain/repositories/progress_repository_contract.dart';
import '../remote_data_source/progress/analytics_remote_data_source.dart';
import '../remote_data_source/progress/badge_remote_data_source.dart';
import '../remote_data_source/progress/progress_remote_data_source.dart';
import '../repository/analytics_repository.dart';
import '../repository/badge_repository.dart';
import '../repository/progress_repository.dart';

/// Data sources y repositorios del módulo progress.
void registerProgressData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => BadgeRemoteDataSource(getIt()))
    ..registerLazySingleton(() => AnalyticsRemoteDataSource(getIt()))
    ..registerLazySingleton(() => ProgressRemoteDataSource(getIt()))
    ..registerLazySingleton<BadgeRepositoryContract>(
      () => BadgeRepository(getIt()),
    )
    ..registerLazySingleton<AnalyticsRepositoryContract>(
      () => AnalyticsRepository(getIt()),
    )
    ..registerLazySingleton<ProgressRepositoryContract>(
      () => ProgressRepository(getIt()),
    );
}
