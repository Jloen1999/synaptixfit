import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/analytics_enums.dart';
import 'package:synaptixfit/domain/enums/analytics_period.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/repositories/account_repository_contract.dart';
import 'package:synaptixfit/domain/repositories/analytics_repository_contract.dart';
import 'package:synaptixfit/domain/repositories/badge_repository_contract.dart';
import 'package:synaptixfit/domain/repositories/progress_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_analytics_report_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_progress_overview_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_unnotified_badges_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/mark_badges_notified_use_case.dart';

import '../../progress_fixtures.dart';

class _MockAccount extends Mock implements AccountRepositoryContract {}

class _MockBadges extends Mock implements BadgeRepositoryContract {}

class _MockAnalytics extends Mock implements AnalyticsRepositoryContract {}

class _MockProgress extends Mock implements ProgressRepositoryContract {}

void main() {
  late _MockAccount account;
  late _MockBadges badges;
  late _MockAnalytics analytics;
  late _MockProgress progress;

  setUpAll(() {
    registerFallbackValue(AnalyticsPeriod.weekly);
    registerFallbackValue(CorrelationMetric.rpe);
  });

  setUp(() {
    account = _MockAccount();
    badges = _MockBadges();
    analytics = _MockAnalytics();
    progress = _MockProgress();
    when(
      () => account.getAccount(),
    ).thenAnswer((_) async => const Success(testAccount));
    when(
      () => badges.getStreak(),
    ).thenAnswer((_) async => const Success(testStreak));
    when(
      () => badges.getMine(includeHidden: any(named: 'includeHidden')),
    ).thenAnswer(
      (_) async => Success([
        testBadge(id: 'old'),
        testBadge(id: 'new').copyWith(earnedAt: DateTime(2026, 10, 10)),
      ]),
    );
    when(
      () => analytics.getWeekly(any()),
    ).thenAnswer((_) async => const Failure(AppError.server()));
    when(
      () => progress.getPhysicalLoad(),
    ).thenAnswer((_) async => const Failure(AppError.network()));
    when(
      () => progress.getCommunityPreview(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => analytics.getStudyWeek(),
    ).thenAnswer((_) async => const Failure(AppError.network()));
    when(
      () => analytics.getStudyBySubject(),
    ).thenAnswer((_) async => const Failure(AppError.network()));
  });

  GetProgressOverviewUseCase overview() => GetProgressOverviewUseCase(
    account: account,
    badges: badges,
    analytics: analytics,
    progress: progress,
  );

  test('solo lee y tolera fallos en las secciones secundarias', () async {
    final result = await overview()();

    final value = result.valueOrNull!;
    expect(value.weekly, isNull);
    expect(value.physicalLoad, isNull);
    expect(value.communityPosts, isEmpty);
    expect(value.studyWeek, isNull);
    // Las insignias se ordenan de la más reciente a la más antigua.
    expect(value.earnedBadges.map((b) => b.id), ['new', 'old']);
    verify(() => badges.getMine(includeHidden: true)).called(1);
    // Un caso de uso «Get» no escribe: las insignias las otorga el servidor.
    verifyNever(() => badges.markNotified(any()));
  });

  test('las insignias nuevas son las no celebradas del servidor', () async {
    when(
      () => badges.getUnnotified(),
    ).thenAnswer((_) async => Success([testBadge(id: 'b9')]));
    final result = await GetUnnotifiedBadgesUseCase(badges)();
    expect(result.valueOrNull?.map((b) => b.id), ['b9']);
  });

  test('marcar como celebradas sin ids no llama a la API', () async {
    final result = await MarkBadgesNotifiedUseCase(badges)(const []);
    expect(result.isSuccess, isTrue);
    verifyNever(() => badges.markNotified(any()));
  });

  test('marca como celebradas las insignias indicadas', () async {
    when(
      () => badges.markNotified(any()),
    ).thenAnswer((_) async => const Success(unit));
    await MarkBadgesNotifiedUseCase(badges)(const ['b1', 'b2']);
    verify(() => badges.markNotified(const ['b1', 'b2'])).called(1);
  });

  test('falla si no se puede cargar la racha', () async {
    when(() => badges.getStreak()).thenAnswer(
      (_) async => const Failure(AppError.business('STREAK_INVALID_ZONE')),
    );
    expect(
      (await overview()()).errorOrNull,
      const AppError.business('STREAK_INVALID_ZONE'),
    );
  });

  test('el informe de analítica falla con el primer error', () async {
    when(
      () => analytics.getWeekly(any()),
    ).thenAnswer((_) async => Success(testWeekly));
    when(
      () => analytics.getVolume(any()),
    ).thenAnswer((_) async => const Failure(AppError.network()));
    when(
      () => analytics.getRpeTrend(any()),
    ).thenAnswer((_) async => Success(testReport().rpeTrend));
    when(
      () => analytics.getCorrelation(any()),
    ).thenAnswer((_) async => Success(testCorrelation(CorrelationMetric.rpe)));
    when(
      () => analytics.getInsights(any()),
    ).thenAnswer((_) async => const Success([]));

    final result = await GetAnalyticsReportUseCase(analytics)(
      period: AnalyticsPeriod.monthly,
      metric: CorrelationMetric.rpe,
    );
    expect(result.errorOrNull, const AppError.network());
  });
}
