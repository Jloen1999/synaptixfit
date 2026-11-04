import 'package:get_it/get_it.dart';

import '../use_cases/progress/change_badge_visibility_use_case.dart';
import '../use_cases/progress/get_analytics_report_use_case.dart';
import '../use_cases/progress/get_badge_catalog_use_case.dart';
import '../use_cases/progress/get_load_correlation_use_case.dart';
import '../use_cases/progress/get_progress_overview_use_case.dart';
import '../use_cases/progress/get_unnotified_badges_use_case.dart';
import '../use_cases/progress/mark_badges_notified_use_case.dart';
import '../use_cases/progress/share_achievement_image_use_case.dart';
import '../use_cases/progress/share_badge_use_case.dart';
import '../use_cases/progress/get_streak_use_case.dart';

/// Casos de uso del módulo progress.
void registerProgressDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<GetStreakUseCaseContract>(
      () => GetStreakUseCase(getIt()),
    )
    ..registerLazySingleton<GetProgressOverviewUseCaseContract>(
      () => GetProgressOverviewUseCase(
        account: getIt(),
        badges: getIt(),
        analytics: getIt(),
        progress: getIt(),
      ),
    )
    ..registerLazySingleton<GetUnnotifiedBadgesUseCaseContract>(
      () => GetUnnotifiedBadgesUseCase(getIt()),
    )
    ..registerLazySingleton<MarkBadgesNotifiedUseCaseContract>(
      () => MarkBadgesNotifiedUseCase(getIt()),
    )
    ..registerLazySingleton<GetBadgeCatalogUseCaseContract>(
      () => GetBadgeCatalogUseCase(getIt()),
    )
    ..registerLazySingleton<ChangeBadgeVisibilityUseCaseContract>(
      () => ChangeBadgeVisibilityUseCase(getIt()),
    )
    ..registerLazySingleton<ShareBadgeUseCaseContract>(
      () => ShareBadgeUseCase(getIt()),
    )
    ..registerLazySingleton<ShareAchievementImageUseCaseContract>(
      () => ShareAchievementImageUseCase(getIt()),
    )
    ..registerLazySingleton<GetAnalyticsReportUseCaseContract>(
      () => GetAnalyticsReportUseCase(getIt()),
    )
    ..registerLazySingleton<GetLoadCorrelationUseCaseContract>(
      () => GetLoadCorrelationUseCase(getIt()),
    );
}
