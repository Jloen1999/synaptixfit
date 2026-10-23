import 'package:get_it/get_it.dart';

import '../../domain/repositories/deadline_repository_contract.dart';
import '../../domain/repositories/focus_repository_contract.dart';
import '../../domain/repositories/planner_repository_contract.dart';
import '../remote_data_source/planner/planner_remote_data_source.dart';
import '../repository/deadline_repository.dart';
import '../repository/focus_repository.dart';
import '../repository/planner_repository.dart';

/// Data sources y repositorios del módulo planner.
void registerPlannerData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => PlannerRemoteDataSource(getIt()))
    ..registerLazySingleton<PlannerRepositoryContract>(
      () => PlannerRepository(getIt()),
    )
    ..registerLazySingleton<DeadlineRepositoryContract>(
      () => DeadlineRepository(getIt()),
    )
    ..registerLazySingleton<FocusRepositoryContract>(
      () => FocusRepository(getIt()),
    );
}
