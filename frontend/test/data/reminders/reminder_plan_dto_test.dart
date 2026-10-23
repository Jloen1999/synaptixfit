import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/reminders/dto/reminder_plan_dto.dart';
import 'package:synaptixfit/domain/enums/reminder_kind.dart';

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
  });
}
