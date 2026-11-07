import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/reminder_kind.dart';
import 'package:synaptixfit/domain/models/reminders/reminder.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_composer.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_plan.dart';

import 'reminder_test_texts.dart';

/// Avisos con botones («Empezar», «Posponer») y avisos de entrega que abren
/// esa entrega concreta.
void main() {
  const composer = ReminderComposer();
  const texts = TestReminderTexts();
  final at = DateTime.utc(2026, 11, 4, 16);

  test('los eventos llevan «Empezar» y «Posponer 10 min»', () {
    final reminders = composer.compose([
      PlannedReminder(kind: ReminderKind.studyBlock, at: at, refId: 'b1'),
      PlannedReminder(kind: ReminderKind.sportBlock, at: at, refId: 'b2'),
      PlannedReminder(kind: ReminderKind.weeklySummary, at: at, refId: 'w'),
      PlannedReminder(kind: ReminderKind.personalEvent, at: at, refId: 'p1'),
      PlannedReminder(kind: ReminderKind.morningSummary, at: at, refId: 'd'),
    ], texts);

    expect(reminders[0].hasActions, isTrue);
    expect(reminders[0].startLabel, 'start:studyBlock');
    expect(reminders[0].snoozeLabel, 'snooze:10');
    expect(reminders[1].startLabel, 'start:sportBlock');
    // El resumen de la semana no es algo que «empezar».
    expect(reminders[2].hasActions, isFalse);
    // El evento personal también se pospone; «Empezar» solo abre la app.
    expect(reminders[3].startLabel, 'start:personalEvent');
    expect(reminders[3].snoozeLabel, 'snooze:10');
    expect(reminders[4].hasActions, isFalse);
  });

  test('el aviso de una entrega abre esa entrega (sin los días antes)', () {
    final reminders = composer.compose([
      PlannedReminder(
        kind: ReminderKind.deadline,
        at: at,
        refId: 'd1:3',
        count: 3,
        startsAt: at.add(const Duration(days: 3)),
      ),
    ], texts);

    expect(reminders.single.refId, 'd1');
    expect(reminders.single.payload, 'deadline|d1');
  });

  test('si el servidor manda la entrega aparte (targetId), se abre esa', () {
    final reminders = composer.compose([
      PlannedReminder(
        kind: ReminderKind.exam,
        at: at,
        refId: 'e7:1',
        count: 1,
        startsAt: at.add(const Duration(days: 1)),
        targetId: 'e7',
      ),
    ], texts);

    expect(reminders.single.refId, 'e7');
  });

  test(
    'un aviso pospuesto (con datos al final) sigue abriendo lo que anuncia',
    () {
      expect(
        OpenedReminder.fromPayload('studyBlock|b1|t=Hora&b=Repaso'),
        const OpenedReminder(kind: ReminderKind.studyBlock, refId: 'b1'),
      );
      expect(
        OpenedReminder.fromPayload('studyBlock|b1', start: true),
        const OpenedReminder(
          kind: ReminderKind.studyBlock,
          refId: 'b1',
          start: true,
        ),
      );
    },
  );
}
