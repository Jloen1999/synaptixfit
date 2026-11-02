import 'package:get_it/get_it.dart';

import '../../domain/repositories/pending_sets_repository_contract.dart';
import '../../domain/repositories/exercise_repository_contract.dart';
import '../../domain/repositories/routine_repository_contract.dart';
import '../../domain/repositories/session_clock_intro_repository_contract.dart';
import '../../domain/repositories/training_history_repository_contract.dart';
import '../../domain/repositories/training_repository_contract.dart';
import '../remote_data_source/training/exercise_remote_data_source.dart';
import '../remote_data_source/training/routine_remote_data_source.dart';
import '../remote_data_source/training/training_history_remote_data_source.dart';
import '../remote_data_source/training/training_remote_data_source.dart';
import '../local_data_source/pending_sets_storage.dart';
import '../local_data_source/session_clock_intro_storage.dart';
import '../repository/pending_sets_repository.dart';
import '../repository/exercise_repository.dart';
import '../repository/routine_repository.dart';
import '../repository/session_clock_intro_repository.dart';
import '../repository/training_history_repository.dart';
import '../repository/training_repository.dart';

/// Data sources y repositorios del módulo training.
void registerTrainingData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => ExerciseRemoteDataSource(getIt()))
    ..registerLazySingleton(() => RoutineRemoteDataSource(getIt()))
    ..registerLazySingleton(() => TrainingRemoteDataSource(getIt()))
    ..registerLazySingleton(() => TrainingHistoryRemoteDataSource(getIt()))
    ..registerLazySingleton(PendingSetsStorage.new)
    ..registerLazySingleton<PendingSetsRepositoryContract>(
      () => PendingSetsRepository(getIt()),
    )
    ..registerLazySingleton<SessionClockIntroStorage>(
      SharedPrefsSessionClockIntroStorage.new,
    )
    ..registerLazySingleton<SessionClockIntroRepositoryContract>(
      () => SessionClockIntroRepository(getIt()),
    )
    ..registerLazySingleton<TrainingHistoryRepositoryContract>(
      () => TrainingHistoryRepository(getIt()),
    )
    ..registerLazySingleton<ExerciseRepositoryContract>(
      () => ExerciseRepository(getIt()),
    )
    ..registerLazySingleton<RoutineRepositoryContract>(
      () => RoutineRepository(getIt()),
    )
    ..registerLazySingleton<TrainingRepositoryContract>(
      () => TrainingRepository(getIt()),
    );
}
