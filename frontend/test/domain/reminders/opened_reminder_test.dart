import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/reminder_kind.dart';
import 'package:synaptixfit/domain/models/reminders/reminder.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_composer.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_plan.dart';

import 'reminder_test_texts.dart';

/// Tocar un aviso abre lo que anuncia: el `payload` lleva tipo y referencia.
void main() {
  test('el payload lleva tipo y referencia y se lee de vuelta', () {
    final reminder = Reminder(
      id: 1,
      kind: ReminderKind.studyBlock,
      title: 't',
      body: 'b',
      at: DateTime(2026, 11, 2),
      refId: 'b1',
    );
    expect(reminder.payload, 'studyBlock|b1');
    expect(
      OpenedReminder.fromPayload(reminder.payload),
      const OpenedReminder(kind: ReminderKind.studyBlock, refId: 'b1'),
    );
  });

  test(
    'los avisos de versiones anteriores (solo el tipo) siguen abriendo su pantalla',
    () {
      expect(
        OpenedReminder.fromPayload('dueReviews'),
        const OpenedReminder(kind: ReminderKind.dueReviews),
      );
      expect(OpenedReminder.fromPayload('desconocido|x'), isNull);
      expect(OpenedReminder.fromPayload(null), isNull);
    },
  );

  test(
    'los avisos de seguimiento llevan su texto, su referencia y un id propio',
    () {
      final at = DateTime.utc(2026, 11, 3, 9);
      final reminders = const ReminderComposer().compose([
        PlannedReminder(
          kind: ReminderKind.routineDayMissed,
          at: at,
          refId: 'd1',
          title: 'Fuerza',
        ),
        PlannedReminder(kind: ReminderKind.openSession, at: at, refId: 's1'),
        PlannedReminder(
          kind: ReminderKind.challengeDue,
          at: at,
          refId: 'c1',
          title: '10 km',
        ),
      ], const TestReminderTexts());

      expect(reminders.map((r) => r.body), [
        'routineDayMissed:Fuerza',
        'openSession:-',
        'challengeDue:10 km',
      ]);
      expect(reminders.map((r) => r.refId), ['d1', 's1', 'c1']);
      expect(reminders.map((r) => r.id).toSet(), hasLength(3));
    },
  );

  test('los avisos de ADR 0035 se abren por su tipo y referencia', () {
    expect(
      OpenedReminder.fromPayload('personalEvent|p1'),
      const OpenedReminder(kind: ReminderKind.personalEvent, refId: 'p1'),
    );
    expect(
      OpenedReminder.fromPayload('challengeTask|ch1'),
      const OpenedReminder(kind: ReminderKind.challengeTask, refId: 'ch1'),
    );
    expect(
      OpenedReminder.fromPayload('morningSummary|2026-11-08'),
      const OpenedReminder(
        kind: ReminderKind.morningSummary,
        refId: '2026-11-08',
      ),
    );
    expect(ReminderKind.fromApi('PERSONAL_EVENT'), ReminderKind.personalEvent);
    expect(ReminderKind.fromApi('CHALLENGE_TASK'), ReminderKind.challengeTask);
    expect(
      ReminderKind.fromApi('MORNING_SUMMARY'),
      ReminderKind.morningSummary,
    );
    // Hueco para el aviso de cumpleaños: aún no existe en esta versión.
    expect(ReminderKind.fromApi('BIRTHDAY'), isNull);
  });

  test('el plan del servidor trae los tipos nuevos', () {
    expect(ReminderKind.fromApi('CHALLENGE_DUE'), ReminderKind.challengeDue);
    expect(ReminderKind.fromApi('OPEN_SESSION'), ReminderKind.openSession);
    expect(
      ReminderKind.fromApi('ROUTINE_DAY_MISSED'),
      ReminderKind.routineDayMissed,
    );
  });
}
