import 'dart:async';

import '../../enums/analytics_period.dart';
import '../../models/progress/progress_overview.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/account_repository_contract.dart';
import '../../repositories/analytics_repository_contract.dart';
import '../../repositories/badge_repository_contract.dart';
import '../../repositories/progress_repository_contract.dart';

/// Reúne los datos de la pestaña Progreso en paralelo (solo lectura: las
/// insignias ya las otorga el servidor). Cuenta, racha e insignias son
/// obligatorias; el resumen semanal, la carga física, la comunidad y «Tu
/// estudio», opcionales.
abstract interface class GetProgressOverviewUseCaseContract {
  Future<AppResult<ProgressOverview>> call();
}

class GetProgressOverviewUseCase implements GetProgressOverviewUseCaseContract {
  const GetProgressOverviewUseCase({
    required this._account,
    required this._badges,
    required this._analytics,
    required this._progress,
  });

  final AccountRepositoryContract _account;
  final BadgeRepositoryContract _badges;
  final AnalyticsRepositoryContract _analytics;
  final ProgressRepositoryContract _progress;

  @override
  Future<AppResult<ProgressOverview>> call() async {
    final (account, streak, earned, weekly, load, posts, study) = await (
      _account.getAccount(),
      _badges.getStreak(),
      _badges.getMine(includeHidden: true),
      _analytics.getWeekly(AnalyticsPeriod.weekly),
      _progress.getPhysicalLoad(),
      _progress.getCommunityPreview(),
      _analytics.getStudyWeek(),
    ).wait;

    return switch ((account, streak, earned)) {
      (
        Success(value: final a),
        Success(value: final s),
        Success(value: final e),
      ) =>
        Success(
          ProgressOverview(
            account: a,
            streak: s,
            earnedBadges: [...e]
              ..sort((x, y) => _byRecent(x.earnedAt, y.earnedAt)),
            weekly: weekly.valueOrNull,
            physicalLoad: load.valueOrNull,
            communityPosts: posts.valueOrNull,
            studyWeek: study.valueOrNull,
          ),
        ),
      (Failure(:final error), _, _) ||
      (_, Failure(:final error), _) ||
      (_, _, Failure(:final error)) => Failure(error),
    };
  }

  static int _byRecent(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
