import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/progress/dto/analytics_dto.dart';
import 'package:synaptixfit/data/remote_data_source/progress/dto/badge_dto.dart';
import 'package:synaptixfit/data/remote_data_source/progress/dto/community_post_dto.dart';
import 'package:synaptixfit/data/remote_data_source/progress/dto/physical_load_dto.dart';
import 'package:synaptixfit/data/remote_data_source/progress/dto/streak_dto.dart';
import 'package:synaptixfit/domain/enums/analytics_enums.dart';
import 'package:synaptixfit/domain/enums/analytics_period.dart';
import 'package:synaptixfit/domain/enums/badge_category.dart';
import 'package:synaptixfit/domain/enums/badge_criterion.dart';
import 'package:synaptixfit/domain/enums/badge_rarity.dart';
import 'package:synaptixfit/domain/enums/community_post_kind.dart';

void main() {
  group('BadgeDto', () {
    test('mapea enums de la API y convierte earnedAt a hora local', () {
      final badge = BadgeDto.fromJson({
        'id': 'b1',
        'name': 'Leyenda',
        'description': 'Racha de 100 días',
        'icon': '👑',
        'category': 'STREAK',
        'criterionType': 'STREAK_DAYS',
        'criterionValue': 100,
        'rarity': 'LEGENDARY',
        'order': 13,
        'earned': true,
        'earnedAt': '2026-10-01T10:00:00Z',
        'notified': true,
        'visible': true,
        'currentValue': 104,
        'progress': 1.0,
      }).toDomain();

      expect(badge.category, BadgeCategory.streak);
      expect(badge.criterion, BadgeCriterion.streakDays);
      expect(badge.rarity, BadgeRarity.legendary);
      expect(badge.earnedAt!.isUtc, isFalse);
      expect(badge.earnedAt, DateTime.utc(2026, 10, 1, 10).toLocal());
    });

    test(
      'una bloqueada nunca es visible y los valores raros caen a defecto',
      () {
        final badge = BadgeDto.fromJson({
          'id': 'b2',
          'name': 'X',
          'category': 'OTHER',
          'criterionType': 'NEW_CRITERION',
          'rarity': null,
          'earned': false,
          'visible': true,
          'progress': 1.7,
        }).toDomain();

        expect(badge.visible, isFalse);
        expect(badge.category, BadgeCategory.special);
        expect(badge.criterion, BadgeCriterion.unknown);
        expect(badge.rarity, BadgeRarity.common);
        expect(badge.progress, 1);
      },
    );
  });

  test('StreakDto normaliza el hito y el récord', () {
    final streak = StreakDto.fromJson({
      'currentDays': 400,
      'bestDays': 380,
      'activeToday': true,
      'atRisk': false,
      'nextMilestone': 0,
      'daysToNextMilestone': -1,
      'milestoneProgress': 1.0,
      'reachedMilestones': [365, 7, 100, 30],
    }).toDomain();

    expect(streak.nextMilestone, isNull);
    expect(streak.bestDays, 400);
    expect(streak.daysToNextMilestone, 0);
    expect(streak.reachedMilestones, [7, 30, 100, 365]);
  });

  test('CorrelationDto sin datos suficientes anula coeficiente y fuerza', () {
    final c = CorrelationDto.fromJson({
      'metric': 'MINUTES',
      'coefficient': null,
      'sampleSize': 2,
      'minimumSampleSize': 4,
      'sufficientData': false,
      'strength': null,
      'direction': null,
      'points': [
        {'weekStart': '2026-10-05', 'studyHours': 10.5, 'trainingValue': 90},
      ],
    }).toDomain();

    expect(c.metric, CorrelationMetric.minutes);
    expect(c.sufficientData, isFalse);
    expect(c.coefficient, isNull);
    expect(c.strength, isNull);
    expect(c.points.single.weekStart, DateTime(2026, 10, 5));
  });

  test('CorrelationDto con datos mapea fuerza y dirección', () {
    final c = CorrelationDto.fromJson({
      'metric': 'RPE',
      'coefficient': -0.71,
      'sampleSize': 8,
      'minimumSampleSize': 4,
      'sufficientData': true,
      'strength': 'VERY_STRONG',
      'direction': 'NEGATIVE',
      'points': <dynamic>[],
    }).toDomain();

    expect(c.strength, CorrelationStrength.veryStrong);
    expect(c.direction, CorrelationDirection.negative);
  });

  test('WeeklyAnalyticsDto y RpeTrendDto mapean periodo y dirección', () {
    final weekly = WeeklyAnalyticsDto.fromJson({
      'period': 'QUARTERLY',
      'weeks': [
        {
          'weekStart': '2026-10-12',
          'sessions': 0,
          'averageRpe': null,
          'totalMinutes': 0,
          'totalCalories': 0,
        },
      ],
      'totalSessions': 0,
      'totalMinutes': 0,
      'totalCalories': 0,
      'averageRpe': null,
    }).toDomain();
    expect(weekly.period, AnalyticsPeriod.quarterly);
    expect(weekly.hasData, isFalse);
    expect(weekly.weeks.single.averageRpe, isNull);

    final trend = RpeTrendDto.fromJson({
      'points': [
        {'weekStart': '2026-10-05', 'averageRpe': 6.5},
      ],
      'slopePerWeek': 0.3,
      'direction': 'UP',
    }).toDomain();
    expect(trend.direction, TrendDirection.up);
  });

  test('InsightDto conserva variante y parámetros', () {
    final insight = InsightDto.fromJson({
      'type': 'VOLUME',
      'severity': 'WARNING',
      'variant': 'LOW',
      'params': {'totalMinutes': 30, 'totalHours': 0.5},
    }).toDomain();

    expect(insight.type, InsightType.volume);
    expect(insight.severity, InsightSeverity.warning);
    expect(insight.params['totalHours'], 0.5);
  });

  test('PhysicalLoadDto ordena los días y calcula la media', () {
    final load = PhysicalLoadDto.fromJson({
      'date': '2026-10-18',
      'todayLoad': 300,
      'maxDailyLoad': 500,
      'todayRatio': 0.6,
      'last28Days': [
        {'date': '2026-10-18', 'load': 300},
        {'date': '2026-10-17', 'load': 100},
      ],
    }).toDomain();

    expect(load.last28Days.first.date, DateTime(2026, 10, 17));
    expect(load.averageLoad, 200);
    expect(load.hasData, isTrue);
  });

  test('CommunityPostPageDto mapea autor y tipo', () {
    final page = CommunityPostPageDto.fromJson({
      'items': [
        {
          'id': 'p1',
          'author': {'id': 'u2', 'fullName': 'Luis', 'avatarUrl': null},
          'type': 'BADGE_UNLOCKED',
          'description': '🏅 Primeros pasos',
          'createdAt': '2026-10-17T08:00:00Z',
          'likesCount': 3,
          'commentsCount': 1,
          'likedByMe': false,
          'mine': false,
        },
      ],
      'page': 0,
      'size': 3,
      'totalItems': 1,
      'totalPages': 1,
    });
    final post = page.items.single.toDomain();

    expect(post.authorName, 'Luis');
    expect(post.kind, CommunityPostKind.badgeUnlocked);
    expect(post.createdAt.isUtc, isFalse);
  });
}
