import 'package:get_it/get_it.dart';

import '../../domain/repositories/admin_exercise_repository_contract.dart';
import '../../domain/repositories/admin_moderation_repository_contract.dart';
import '../../domain/repositories/admin_repository_contract.dart';
import '../remote_data_source/admin/admin_exercise_remote_data_source.dart';
import '../remote_data_source/admin/admin_moderation_remote_data_source.dart';
import '../remote_data_source/admin/admin_remote_data_source.dart';
import '../repository/admin_exercise_repository.dart';
import '../repository/admin_moderation_repository.dart';
import '../repository/admin_repository.dart';

/// Data sources y repositorios del módulo admin.
void registerAdminData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => AdminRemoteDataSource(getIt()))
    ..registerLazySingleton(() => AdminModerationRemoteDataSource(getIt()))
    ..registerLazySingleton(() => AdminExerciseRemoteDataSource(getIt()))
    ..registerLazySingleton<AdminRepositoryContract>(
      () => AdminRepository(getIt()),
    )
    ..registerLazySingleton<AdminModerationRepositoryContract>(
      () => AdminModerationRepository(getIt()),
    )
    ..registerLazySingleton<AdminExerciseRepositoryContract>(
      () => AdminExerciseRepository(getIt()),
    );
}
