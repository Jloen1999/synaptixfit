import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/training/dto/wellbeing_extra_dtos.dart';
import 'package:synaptixfit/domain/enums/reminder_task_timing.dart';
import 'package:synaptixfit/domain/models/profile/notification_preferences.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_options.dart';

/// Lectura y escritura de `/notifications/reminder-options` (ADR 0035).
void main() {
  const loaded = ReminderOptions();

  group('JSON de reminder-options', () {
    test('lee los campos nuevos y rellena los que falten', () {
      final options = WellbeingExtraDtos.reminderOptions({
        'streak': true,
        'checkIn': false,
        'classes': true,
        'eventLeadMinutes': 30,
        'deadlineDaysBefore': [7, 1],
        'taskTiming': 'MORNING_OF',
        'morningSummary': true,
        'morningSummaryAt': '07:30:00',
      });
      expect(options.eventLeadMinutes, 30);
      expect(options.deadlineDaysBefore, [1, 7]);
      expect(options.taskTiming, ReminderTaskTiming.morningOf);
      expect(options.morningSummaryAt, const ClockTime(hour: 7, minute: 30));

      // Un servidor anterior solo manda los tres interruptores.
      final old = WellbeingExtraDtos.reminderOptions({
        'streak': false,
        'checkIn': true,
        'classes': true,
      });
      expect(old, const ReminderOptions(streak: false));
    });

    test('con el resumen apagado manda morningSummary false y sin hora', () {
      final body = WellbeingExtraDtos.reminderOptionsBody(
        const ReminderOptions(
          morningSummary: false,
          taskTiming: ReminderTaskTiming.morningOf,
        ),
      );
      expect(body['morningSummary'], isFalse);
      expect(body['morningSummaryAt'], isNull);
      expect(body['taskTiming'], 'MORNING_OF');
      expect(body['deadlineDaysBefore'], [1, 3]);
      expect(body['eventLeadMinutes'], 15);
      expect(
        WellbeingExtraDtos.reminderOptionsBody(loaded)['morningSummaryAt'],
        '08:00:00',
      );
    });

    test('las horas del resumen van de 05:00 a 12:00 cada media hora', () {
      final times = ReminderOptions.summaryTimeChoices;
      expect(times.first, const ClockTime(hour: 5, minute: 0));
      expect(times.last, const ClockTime(hour: 12, minute: 0));
      expect(times, hasLength(15));
    });
  });
}
