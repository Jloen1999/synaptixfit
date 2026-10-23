import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/reminder_kind.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_composer.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_plan.dart';

import 'reminder_test_texts.dart';

void main() {
  const composer = ReminderComposer();
  const texts = TestReminderTexts();
  // Instantes en hora local para que el texto no dependa de la zona del equipo.
  final start = DateTime(2026, 10, 22, 13);

  PlannedReminder block(String id, {String? title = 'Cuerpo completo A'}) =>
      PlannedReminder(
        kind: ReminderKind.sportBlock,
        at: start.subtract(const Duration(minutes: 15)),
        refId: id,
        title: title,
        startsAt: start,
      );

  PlannedReminder reviews(DateTime at) => PlannedReminder(
    kind: ReminderKind.dueReviews,
    at: at,
    refId: '${at.year}-${at.month}-${at.day}',
    count: 3,
  );

  group('ReminderComposer', () {
    test('pone los textos y respeta el instante decidido', () {
      final reminders = composer.compose([
        reviews(DateTime(2026, 10, 21, 19)),
        block('b1'),
      ], texts);

      expect(reminders.map((r) => r.kind), [
        ReminderKind.dueReviews,
        ReminderKind.sportBlock,
      ]);
      expect(reminders.first.body, 'reviews:3');
      expect(reminders.last.title, 'sportBlock');
      expect(reminders.last.body, 'sportBlock:Cuerpo completo A@13:00');
      expect(reminders.last.at, DateTime(2026, 10, 22, 12, 45));
    });

    test('sin título deja el texto por defecto a los textos', () {
      final reminders = composer.compose([block('b1', title: null)], texts);

      expect(reminders.single.body, 'sportBlock:-@13:00');
    });

    test('ids estables, distintos entre bloques y lejos de los repasos', () {
      final first = composer.compose([block('b1')], texts).single.id;
      final again = composer.compose([block('b1')], texts).single.id;
      final other = composer.compose([block('b2')], texts).single.id;
      final review = composer.compose([
        reviews(DateTime(2026, 10, 21, 19)),
        reviews(DateTime(2026, 10, 22, 19)),
      ], texts);

      expect(first, again);
      expect(first, isNot(other));
      expect(first, greaterThanOrEqualTo(1000));
      expect(first, lessThan(1 << 31));
      expect(review.map((r) => r.id), [100, 101]);
    });

    test('no pasa del tope del dispositivo', () {
      const small = ReminderComposer(maxReminders: 1);

      expect(small.compose([block('b1'), block('b2')], texts), hasLength(1));
    });
  });
}
