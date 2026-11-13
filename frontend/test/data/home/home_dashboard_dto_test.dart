import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/cognitive_level.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/data/remote_data_source/home/dto/home_dashboard_dto.dart';
import 'package:synaptixfit/data/remote_data_source/home/dto/home_due_review_dto.dart';
import 'package:synaptixfit/domain/enums/home_acwr_zone.dart';
import 'package:synaptixfit/domain/enums/home_banner_type.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';

void main() {
  final json = <String, dynamic>{
    'greeting': {
      'fullName': 'Ana López',
      'avatarUrl': null,
      'level': 3,
      'levelXp': 120,
      'levelThreshold': 300,
      'streak': 4,
    },
    'today': {
      'date': '2026-10-18',
      'trainingCalories': 320,
      'studyCalories': 95.2,
      'totalCalories': 1820.6,
      'sessions': 1,
      'trainingMinutes': 45,
      'studyMinutesCompleted': 60,
      'studyMinutesPlanned': 120,
      'physicalLoad': 1.2,
    },
    'week': {
      'weekStart': '2026-10-12',
      'sessions': 3,
      'plannedSessions': null,
      'remainingSessions': null,
      'trainingMinutes': 150,
      'trainingCalories': 980.5,
      'studyMinutesCompleted': 420,
    },
    'cognitive': {
      'cognitiveLoad': 1.4,
      'attentionCapacity': 0.81,
      'lastBlockMinutes': 50,
      'lastRestAt': null,
      'loadLevel': 'CRITICAL',
      'attentionLevel': 'HIGH',
    },
    'crossRegulation': {
      'acwr': 1.62,
      'zone': 'OVERTRAINING',
      'acuteDailyLoad': 300,
      'chronicDailyLoad': 185,
      'maxStudyMinutes': 180,
    },
    'wellbeing': {
      'date': '2026-10-18',
      'checkInDone': true,
      'fatigueScore': 35,
      'energy': {'score': 64.5, 'base': 60},
      'adherence': null,
    },
    'nextTrainingDay': {
      'routineId': 'r1',
      'routineName': 'Fuerza base',
      'weekId': 'w1',
      'weekNumber': 2,
      'dayId': 'd1',
      'dayNumber': 3,
      'dayName': '  ',
      'status': 'IN_PROGRESS',
    },
    'activeChallenges': [
      {
        'id': 'c1',
        'title': 'Estudiar 10 horas',
        'type': 'ACADEMIC',
        'difficulty': 'MEDIUM',
        'endsAt': '2026-10-25T21:59:59Z',
        'progress': 140.0,
        'currentStreak': 2,
      },
    ],
    'planWeek': [
      {'date': '2026-10-12', 'planned': 3, 'completed': 2},
    ],
    'todayEvents': [
      {
        'kind': 'DEADLINE',
        'id': 'e1',
        'title': 'Práctica 2',
        'type': 'DELIVERY',
        'start': '2026-10-18T21:59:00Z',
        'end': null,
        'completed': false,
        'subjectName': 'Redes',
      },
      {
        'kind': 'BLOCK',
        'id': 'e2',
        'title': 'Clase',
        'type': 'CLASS',
        'start': '2026-10-18T08:00:00Z',
        'end': '2026-10-18T10:00:00Z',
        'completed': true,
        'subjectName': null,
      },
    ],
    'banner': {
      'type': 'PHYSICAL_OVERLOAD',
      'params': {'acwr': 1.62, 'maxStudyMinutes': 180},
    },
    'nextDeadline': {
      'id': 'parcial',
      'title': 'Parcial',
      'type': 'EXAM',
      'dueAt': '2026-11-20T08:00:00Z',
      'subjectName': 'Histología',
    },
  };

  test('mapea el resumen del inicio al dominio', () {
    final dashboard = HomeDashboardDto.fromJson(json).toDomain();

    expect(dashboard.greeting.fullName, 'Ana López');
    expect(dashboard.today.trainingCalories, 320.0);
    expect(dashboard.week.plannedSessions, isNull);
    expect(dashboard.week.trainingCalories, 980.5);
    expect(dashboard.cognitive.cognitiveLoad, 1.0, reason: 'se acota a 0-1');
    expect(dashboard.crossRegulation.zone, HomeAcwrZone.overtraining);
    expect(dashboard.crossRegulation.zone.isRisky, isTrue);
    expect(dashboard.wellbeing.energyScore, 64.5);
    expect(dashboard.wellbeing.adherenceScore, isNull);

    final next = dashboard.nextTrainingDay!;
    expect(next.inProgress, isTrue);
    expect(next.dayName, isNull, reason: 'un nombre en blanco se descarta');

    final challenge = dashboard.activeChallenges.single;
    expect(challenge.academic, isTrue);
    expect(challenge.progress, 100, reason: 'se acota a 0-100');
    expect(challenge.endsAt!.isUtc, isFalse);

    expect(dashboard.planWeek.single.date, DateTime(2026, 10, 12));

    final deadline = dashboard.todayEvents.first;
    expect(deadline.kind, HomeEventKind.deadline);
    expect(deadline.type, HomeEventType.delivery);
    expect(deadline.end, isNull);
    expect(deadline.start, DateTime.utc(2026, 10, 18, 21, 59).toLocal());
    expect(dashboard.todayEvents.last.type, HomeEventType.classSession);

    expect(dashboard.banner.type, HomeBannerType.physicalOverload);
    expect(dashboard.banner.param('maxStudyMinutes'), 180);
    expect(dashboard.banner.param('missing'), 0);

    // Niveles y cuenta atrás los decide el servidor (ADR 0039).
    expect(dashboard.cognitive.loadLevel, CognitiveLevel.critical);
    expect(dashboard.cognitive.attentionLevel, CognitiveLevel.high);
    expect(dashboard.nextDeadline!.type, DeadlineType.exam);
    expect(dashboard.nextDeadline!.dueAt.isUtc, isFalse);
  });

  test('tolera bloques ausentes y tipos desconocidos', () {
    final dashboard = HomeDashboardDto.fromJson({
      'greeting': {'fullName': 'Ana'},
      'today': <String, dynamic>{},
      'banner': {'type': 'SOMETHING_NEW'},
      'todayEvents': [
        {'id': 'x', 'title': 'Algo', 'type': 'UNKNOWN'},
      ],
    }).toDomain();

    expect(dashboard.nextTrainingDay, isNull);
    expect(dashboard.crossRegulation.zone, HomeAcwrZone.noData);
    expect(dashboard.crossRegulation.acwr, isNull);
    expect(dashboard.wellbeing.checkInDone, isFalse);
    expect(dashboard.banner.type, HomeBannerType.balance);
    expect(dashboard.todayEvents.single.kind, HomeEventKind.block);
    expect(dashboard.todayEvents.single.type, HomeEventType.other);
    expect(dashboard.activeChallenges, isEmpty);
  });

  test('mapea los repasos', () {
    final review = HomeDueReviewDto.fromJson({
      'id': 'm1',
      'title': 'Tema 3',
      'nextReviewAt': '2026-10-18T06:00:00Z',
      'masteryState': 'NEEDS_REVIEW',
    }).toDomain();
    expect(review.nextReviewAt, DateTime.utc(2026, 10, 18, 6).toLocal());
  });
}
