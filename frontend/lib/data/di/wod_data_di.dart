import 'package:get_it/get_it.dart';

import '../../domain/repositories/wod_repository_contract.dart';
import '../remote_data_source/training/wod_remote_data_source.dart';
import '../repository/wod_repository.dart';

/// WOD (ADR 0069): todo vive en el servidor.
void registerWodData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => WodRemoteDataSource(getIt()))
    ..registerLazySingleton<WodRepositoryContract>(
      () => WodRepository(getIt()),
    );
}
