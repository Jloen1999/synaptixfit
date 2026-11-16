import 'package:get_it/get_it.dart';

import '../../domain/repositories/guide_progress_repository_contract.dart';
import '../local_data_source/guide_progress_storage.dart';
import '../repository/guide_progress_repository.dart';

/// Guías vistas, guardadas en el teléfono (ADR 0049).
void registerGuidesData(GetIt getIt) {
  getIt
    ..registerLazySingleton<GuideProgressStorage>(
      SharedPrefsGuideProgressStorage.new,
    )
    ..registerLazySingleton<GuideProgressRepositoryContract>(
      () => GuideProgressRepository(getIt()),
    );
}
