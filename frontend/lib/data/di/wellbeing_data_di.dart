import 'package:get_it/get_it.dart';

import '../../domain/repositories/wellbeing_repository_contract.dart';
import '../remote_data_source/training/wellbeing_remote_data_source.dart';
import '../repository/wellbeing_repository.dart';

/// Data source y repositorio de bienestar (ciclo, registro rápido, deporte
/// hecho y avisos opcionales; ADR 0033).
void registerWellbeingData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => WellbeingRemoteDataSource(getIt()))
    ..registerLazySingleton<WellbeingRepositoryContract>(
      () => WellbeingRepository(getIt()),
    );
}
