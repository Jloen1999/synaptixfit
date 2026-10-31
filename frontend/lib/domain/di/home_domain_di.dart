import '../use_cases/home/snooze_home_setup_use_case.dart';
import '../use_cases/home/get_home_setup_use_case.dart';
import 'package:get_it/get_it.dart';

import '../use_cases/home/get_home_dashboard_use_case.dart';
import '../use_cases/home/get_home_due_reviews_use_case.dart';
import '../use_cases/home/get_home_onboarding_status_use_case.dart';
import '../use_cases/home/get_home_unread_count_use_case.dart';

/// Casos de uso del módulo home.
void registerHomeDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<GetHomeDashboardUseCaseContract>(
      () => GetHomeDashboardUseCase(getIt()),
    )
    ..registerLazySingleton<GetHomeDueReviewsUseCaseContract>(
      () => GetHomeDueReviewsUseCase(getIt()),
    )
    ..registerLazySingleton<GetHomeUnreadCountUseCaseContract>(
      () => GetHomeUnreadCountUseCase(getIt()),
    )
    ..registerLazySingleton<GetHomeOnboardingStatusUseCaseContract>(
      () => GetHomeOnboardingStatusUseCase(getIt()),
    )
    ..registerLazySingleton<GetHomeSetupUseCaseContract>(
      () => GetHomeSetupUseCase(getIt(), getIt()),
    )
    ..registerLazySingleton<SnoozeHomeSetupUseCaseContract>(
      () => SnoozeHomeSetupUseCase(getIt()),
    );
}
