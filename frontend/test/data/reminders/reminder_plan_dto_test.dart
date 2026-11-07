import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/reminders/dto/reminder_plan_dto.dart';
import 'package:synaptixfit/domain/enums/reminder_kind.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_plan.dart';

void main() {
  group('ReminderPlanDto', () {
    test('traduce los tipos del servidor y descarta los desconocidos', () {
      final plan = ReminderPlanDto.fromJson({
        'reminders': [
          {
            'kind': 'REVIEWS',
            'at': '2026-10-21T17:00:00Z',
            'refId': '2026-10-21',
            'count': 2,
          },
          {
            'kind': 'STUDY',
            'at': '2026-10-22T06:45:00Z',
            'refId': 'b1',
            'title': 'Matrices',
            'startsAt': '2026-10-22T07:00:00Z',
          },
          {'kind': 'NUEVO', 'at': '2026-10-22T06:45:00Z', 'refId': 'x'},
        ],
      }).toDomain();

      expect(plan.map((p) => p.kind), [
        ReminderKind.dueReviews,
        ReminderKind.studyBlock,
      ]);
      expect(plan.first.count, 2);
      expect(plan.first.at, DateTime.utc(2026, 10, 21, 17));
      expect(plan.last.startsAt, DateTime.utc(2026, 10, 22, 7));
      expect(plan.last.title, 'Matrices');
    });

    test('lee los avisos de ADR 0035 con sus tareas y el resumen', () {
      final plan = ReminderPlanDto.fromJson({
        'reminders': [
          {
            'kind': 'PERSONAL_EVENT',
            'at': '2026-11-08T15:45:00Z',
            'refId': 'p1',
            'title': 'Dentista',
            'startsAt': '2026-11-08T16:00:00Z',
            'tasks': <Object>[],
            'summary': null,
          },
          {
            'kind': 'CHALLENGE_TASK',
            'at': '2026-11-08T17:00:00Z',
            'refId': 'm1:EVENING_BEFORE',
            'count': 1,
            'title': 'Repasar tema 3',
            'startsAt': '2026-11-09T09:00:00Z',
            'targetId': 'ch1',
            'tasks': [
              {
                'challengeId': 'ch1',
                'challengeTitle': 'Aprobar Física',
                'milestoneId': 'm1',
                'title': 'Repasar tema 3',
              },
            ],
          },
          {
            'kind': 'MORNING_SUMMARY',
            'at': '2026-11-09T07:00:00Z',
            'refId': '2026-11-09',
            'tasks': [
              {'challengeId': 'ch2', 'challengeTitle': 'Correr', 'title': null},
            ],
            'summary': {
              'studies': 2,
              'trainings': 1,
              'classes': 0,
              'personal': 1,
              'deadlines': [
                {'title': 'Física', 'exam': false},
              ],
              'tasks': 1,
              'checkIn': true,
            },
          },
          // Felicitación (ADR 0036): llega sola cuando no hay resumen.
          {
            'kind': 'BIRTHDAY',
            'at': '2026-11-10T08:00:00Z',
            'refId': '2026-11-10',
            'title': 'Ana',
          },
          // Los tipos que esta versión no conoce se descartan.
          {'kind': 'FUTURE_KIND', 'at': '2026-11-09T07:00:00Z', 'refId': 'f'},
        ],
      }).toDomain();

      expect(plan.map((p) => p.kind), [
        ReminderKind.personalEvent,
        ReminderKind.challengeTask,
        ReminderKind.morningSummary,
        ReminderKind.birthday,
      ]);
      expect(plan[3].title, 'Ana');
      expect(plan[0].tasks, isEmpty);
      expect(plan[1].targetId, 'ch1');
      expect(
        plan[1].tasks.single,
        const ReminderTask(
          challengeId: 'ch1',
          challengeTitle: 'Aprobar Física',
          milestoneId: 'm1',
          title: 'Repasar tema 3',
        ),
      );
      expect(
        plan[2].summary,
        const ReminderDaySummary(
          studies: 2,
          trainings: 1,
          personal: 1,
          deadlines: [ReminderSummaryDeadline(title: 'Física')],
          tasks: 1,
          checkIn: true,
        ),
      );
      expect(plan[2].tasks.single.title, isNull);
    });
  });
}
