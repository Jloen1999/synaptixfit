import 'package:get_it/get_it.dart';

import '../use_cases/guides/mark_guide_seen_use_case.dart';
import '../use_cases/guides/reset_guides_use_case.dart';
import '../use_cases/guides/should_show_guide_use_case.dart';

/// Casos de uso de las guías la primera vez (ADR 0049).
void registerGuidesDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<ShouldShowGuideUseCaseContract>(
      () => ShouldShowGuideUseCase(getIt()),
    )
    ..registerLazySingleton<MarkGuideSeenUseCaseContract>(
      () => MarkGuideSeenUseCase(getIt()),
    )
    ..registerLazySingleton<ResetGuidesUseCaseContract>(
      () => ResetGuidesUseCase(getIt()),
    );
}
