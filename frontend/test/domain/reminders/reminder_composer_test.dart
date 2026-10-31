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

    test('examen y entrega dicen cuántos días faltan y su título', () {
      final due = DateTime.utc(2026, 10, 24, 7);
      final reminders = composer.compose([
        PlannedReminder(
          kind: ReminderKind.exam,
          at: due.subtract(const Duration(days: 3)),
          refId: 'e1:3',
          count: 3,
          title: 'Parcial',
          startsAt: due,
        ),
        PlannedReminder(
          kind: ReminderKind.deadline,
          at: due.subtract(const Duration(days: 1)),
          refId: 'd1:1',
          count: 1,
          startsAt: due,
        ),
      ], texts);

      expect(reminders.map((r) => r.title), ['exam:3', 'deadline:1']);
      expect(reminders.map((r) => r.body), ['exam:Parcial', 'deadline:-']);
      // Cada aviso (3 días / 1 día) tiene su propio id estable.
      expect(reminders.first.id, isNot(reminders.last.id));
    });

    test('no pasa del tope del dispositivo', () {
      const small = ReminderComposer(maxReminders: 1);

      expect(small.compose([block('b1'), block('b2')], texts), hasLength(1));
    });
  });
}
