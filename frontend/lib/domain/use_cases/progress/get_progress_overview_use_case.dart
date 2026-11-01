import 'dart:async';

import '../../enums/analytics_period.dart';
import '../../models/progress/badge.dart';
import '../../models/progress/progress_overview.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/account_repository_contract.dart';
import '../../repositories/analytics_repository_contract.dart';
import '../../repositories/badge_repository_contract.dart';
import '../../repositories/progress_repository_contract.dart';

/// Reúne los datos de la pestaña Progreso en paralelo (solo lectura: las
/// insignias ya las otorga el servidor). Cuenta, racha e insignias son
/// obligatorias; el resumen semanal, la carga física, la comunidad, «Tu
/// estudio» y la próxima insignia (del catálogo con su progreso), opcionales.
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
    final (
      account,
      streak,
      earned,
      weekly,
      load,
      posts,
      study,
      subjects,
      catalog,
    ) = await (
      _account.getAccount(),
      _badges.getStreak(),
      _badges.getMine(includeHidden: true),
      _analytics.getWeekly(AnalyticsPeriod.weekly),
      _progress.getPhysicalLoad(),
      _progress.getCommunityPreview(),
      _analytics.getStudyWeek(),
      _analytics.getStudyBySubject(),
      _badges.getCatalog(),
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
            studyBySubject: subjects.valueOrNull,
            nextBadge: nextBadge(catalog.valueOrNull ?? const []),
          ),
        ),
      (Failure(:final error), _, _) ||
      (_, Failure(:final error), _) ||
      (_, _, Failure(:final error)) => Failure(error),
    };
  }

  /// La bloqueada con más progreso (el que calcula el servidor); a igualdad,
  /// la primera del catálogo. Solo elige qué enseñar: no decide nada.
  static Badge? nextBadge(List<Badge> catalog) {
    Badge? best;
    for (final badge in catalog.where((b) => !b.earned)) {
      if (best == null ||
          badge.progress > best.progress ||
          (badge.progress == best.progress && badge.order < best.order)) {
        best = badge;
      }
    }
    return best;
  }

  static int _byRecent(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
