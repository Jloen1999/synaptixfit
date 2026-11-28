import 'package:get_it/get_it.dart';

import '../use_cases/training/create_wod_use_case.dart';
import '../use_cases/training/delete_wod_use_case.dart';
import '../use_cases/training/get_wod_board_use_case.dart';
import '../use_cases/training/list_wod_marks_use_case.dart';
import '../use_cases/training/list_wod_templates_use_case.dart';
import '../use_cases/training/save_wod_result_use_case.dart';
import '../use_cases/training/update_wod_use_case.dart';

/// Casos de uso de los WOD (ADR 0069).
void registerWodDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<ListWodTemplatesUseCaseContract>(
      () => ListWodTemplatesUseCase(getIt()),
    )
    ..registerLazySingleton<GetWodBoardUseCaseContract>(
      () => GetWodBoardUseCase(getIt()),
    )
    ..registerLazySingleton<CreateWodUseCaseContract>(
      () => CreateWodUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateWodUseCaseContract>(
      () => UpdateWodUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteWodUseCaseContract>(
      () => DeleteWodUseCase(getIt()),
    )
    ..registerLazySingleton<SaveWodResultUseCaseContract>(
      () => SaveWodResultUseCase(getIt()),
    )
    ..registerLazySingleton<ListWodMarksUseCaseContract>(
      () => ListWodMarksUseCase(getIt()),
    );
}
