import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/planner/dto/calendar_block_dto.dart';
import 'package:synaptixfit/data/remote_data_source/planner/dto/deadline_dto.dart';
import 'package:synaptixfit/data/remote_data_source/planner/dto/focus_dto.dart';
import 'package:synaptixfit/data/remote_data_source/planner/dto/planner_ai_dto.dart';
import 'package:synaptixfit/data/remote_data_source/planner/dto/planner_json.dart';
import 'package:synaptixfit/data/remote_data_source/planner/dto/weekly_planning_dto.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';

void main() {
  group('PlannerJson', () {
    test('instante UTC → hora local y vuelta', () {
      final local = PlannerJson.instant('2025-10-15T08:00:00Z');
      expect(local.isUtc, isFalse);
      expect(local.toUtc(), DateTime.utc(2025, 10, 15, 8));
      expect(PlannerJson.toInstant(local), '2025-10-15T08:00:00.000Z');
    });

    test('fechas y horas locales', () {
      expect(PlannerJson.date('2025-03-07'), DateTime(2025, 3, 7));
      expect(PlannerJson.toDate(DateTime(2025, 3, 7, 22)), '2025-03-07');
      expect(PlannerJson.toLocalTime(18 * 60 + 5), '18:05:00');
    });
  });

  test('CalendarBlockDto mapea enums UPPER_SNAKE_CASE y fechas', () {
    final block = CalendarBlockDto.fromJson({
      'id': 'b1',
      'type': 'CLASS',
      'start': '2025-10-15T08:00:00Z',
      'end': '2025-10-15T09:30:00Z',
      'dayOfWeek': 3,
      'priority': 'HIGH',
      'classKind': 'PRACTICE',
      'privateBlock': true,
      'fixed': true,
      'immovable': false,
      'completed': false,
      'xpReward': 30,
      'subjectId': 's1',
      'metValue': 1.8,
    }).toDomain();

    expect(block.type, BlockType.classSession);
    expect(block.priority, PlannerPriority.high);
    expect(block.classKind, ClassKind.practice);
    expect(block.privateBlock, isTrue);
    expect(block.isLocked, isTrue);
    expect(block.duration, const Duration(minutes: 90));
    expect(block.start.toUtc(), DateTime.utc(2025, 10, 15, 8));
  });

  test('BlockChangeDto incluye los solapes', () {
    Map<String, dynamic> b(String id) => {
      'id': id,
      'type': 'STUDY',
      'start': '2025-10-15T08:00:00Z',
      'end': '2025-10-15T09:00:00Z',
    };
    final change = BlockChangeDto.fromJson({
      'block': b('a'),
      'conflicts': [b('x'), b('y')],
    }).toDomain();
    expect(change.block.id, 'a');
    expect(change.conflicts.map((c) => c.id), ['x', 'y']);
  });

  test('DeadlinePageDto calcula si hay más páginas', () {
    final page = DeadlinePageDto.fromJson({
      'items': [
        {
          'id': 'd1',
          'title': 'Examen',
          'type': 'EXAM',
          'dueAt': '2025-10-20T10:00:00Z',
          'difficulty': 'LOW',
          'imported': true,
        },
      ],
      'page': 0,
      'size': 20,
      'totalItems': 25,
      'totalPages': 2,
    }).toDomain();
    expect(page.hasMore, isTrue);
    expect(page.items.single.type, DeadlineType.exam);
    expect(page.items.single.difficulty, PlannerPriority.low);
    expect(page.items.single.imported, isTrue);
  });

  test('WeekBalanceDto y WeeklyLoadDto', () {
    final balance = WeekBalanceDto.fromJson({
      'weekStart': '2025-10-13',
      'plannedStudyHours': 10.5,
      'actualStudyHours': 2,
      'plannedSportHours': 3,
      'actualSportHours': 0,
      'state': 'STUDY_HEAVY',
    }).toDomain();
    expect(balance.weekStart, DateTime(2025, 10, 13));
    expect(balance.state, BalanceState.studyHeavy);
    expect(balance.actualStudyHours, 2.0);

    final load = WeeklyLoadDto.fromJson({
      'id': 'l1',
      'weekStart': '2025-10-13',
      'plannedHours': 12,
      'actualHours': 4,
      'exams': 1,
      'deliveries': 2,
      'stressLevel': 6,
      'sleepHours': 7,
      'notes': null,
      'xpAwarded': false,
    }).toDomain();
    expect(load.sleepHours, 7.0);
    expect(load.deliveries, 2);
  });

  test('SuggestionDto distingue IA y heurística', () {
    final s = SuggestionDto.fromJson({
      'source': 'HEURISTIC',
      'studyHours': 6.5,
      'sportSessions': 2,
      'blocks': [
        {
          'type': 'SPORT',
          'start': '2025-10-16T16:00:00Z',
          'end': '2025-10-16T17:00:00Z',
          'routineId': 'r1',
          'routineName': 'Fuerza',
        },
      ],
    }).toDomain();
    expect(s.source, SuggestionSource.heuristic);
    expect(s.blocks.single.type, BlockType.sport);
    expect(s.blocks.single.routineName, 'Fuerza');
  });

  test('IcsImportDto y FocusStatsDto', () {
    final ics = IcsImportDto.fromJson({
      'match': 'PARTIAL',
      'totalEvents': 10,
      'matchingEvents': 4,
      'imported': false,
    }).toDomain();
    expect(ics.match, IcsMatch.partial);
    expect(ics.imported, isFalse);

    final stats = FocusStatsDto.fromJson({
      'today': {
        'focusMinutes': 50,
        'breakMinutes': 5,
        'focusCycles': 2,
        'sessions': 3,
      },
      'week': {
        'focusMinutes': 100,
        'breakMinutes': 10,
        'focusCycles': 4,
        'sessions': 6,
      },
      'days': [
        {
          'date': '2025-10-13',
          'totals': {
            'focusMinutes': 25,
            'breakMinutes': 5,
            'focusCycles': 1,
            'sessions': 2,
          },
        },
      ],
    }).toDomain();
    expect(stats.today.focusCycles, 2);
    expect(stats.days.single.date, DateTime(2025, 10, 13));
  });

  test('FocusSessionResponseDto devuelve la XP concedida y su estado', () {
    final result = FocusSessionResponseDto.fromJson({
      'id': 'f1',
      'phase': 'FOCUS',
      'durationMinutes': 25,
      'cycles': 1,
      'completed': true,
      'date': '2025-10-13',
      'blockId': 'b1',
      'subjectId': null,
      'xpAwarded': 5,
      'xpStatus': 'AWARDED',
      'createdAt': '2025-10-13T09:25:00Z',
    }).toDomain();
    expect(result.xpAwarded, 5);
    expect(result.xpStatus, FocusXpStatus.awarded);
    final capped = FocusSessionResponseDto.fromJson({
      'xpStatus': 'DAILY_CAP_REACHED',
    }).toDomain();
    expect(capped.xpStatus, FocusXpStatus.dailyCapReached);
    final empty = FocusSessionResponseDto.fromJson({}).toDomain();
    expect(empty.xpAwarded, 0);
    expect(empty.xpStatus, FocusXpStatus.notEligible);
  });

  test('TimelineItemDto distingue bloques y entregas', () {
    final item = TimelineItemDto.fromJson({
      'kind': 'DEADLINE',
      'id': 'd1',
      'deadlineType': 'PRESENTATION',
      'title': 'Exposición',
      'start': '2025-10-17T09:00:00Z',
      'end': null,
      'completed': false,
    }).toDomain();
    expect(item.kind, TimelineKind.deadline);
    expect(item.deadlineType, DeadlineType.presentation);
    expect(item.blockType, isNull);
  });
}
