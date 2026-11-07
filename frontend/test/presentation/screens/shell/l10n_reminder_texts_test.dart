import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/reminder_kind.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_plan.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/shell/widgets/l10n_reminder_texts.dart';

/// Textos reales de los avisos de ADR 0035: evento personal, tarea de reto,
/// resumen de la mañana (plurales y lista natural) y menciones de tareas.
void main() {
  final es = L10nReminderTexts(lookupAppLocalizations(const Locale('es')));
  final en = L10nReminderTexts(lookupAppLocalizations(const Locale('en')));
  final five = DateTime(2026, 11, 8, 17);
  const task = ReminderTask(
    challengeId: 'ch1',
    challengeTitle: 'Aprobar Física',
    title: 'Repasar tema 3',
  );

  test('evento personal: nombre y hora, y cuánto falta', () {
    expect(es.personalTitle('Dentista', five), 'Dentista a las 17:00');
    expect(es.personalTitle(null, five), 'Tu evento a las 17:00');
    expect(es.personalBody(30), 'Empieza en 30 min');
    expect(es.personalBody(0), 'Empieza ahora');
  });

  test('tarea de reto: hoy o mañana, la tarea y su reto', () {
    expect(
      es.challengeTaskBody(1, 'Repasar tema 3', 'Aprobar Física'),
      'Mañana: Repasar tema 3 · reto «Aprobar Física»',
    );
    expect(
      es.challengeTaskBody(0, 'Repasar tema 3', 'Aprobar Física'),
      'Hoy: Repasar tema 3 · reto «Aprobar Física»',
    );
    // Sin título es el propio reto.
    expect(
      es.challengeTaskBody(1, null, 'Correr 10 km'),
      'Mañana: reto «Correr 10 km»',
    );
  });

  test('resumen de la mañana con plurales y lista natural', () {
    const summary = ReminderDaySummary(
      studies: 2,
      trainings: 1,
      deadlines: [ReminderSummaryDeadline(title: 'Física')],
      tasks: 1,
    );
    expect(
      es.morningSummaryBody(summary),
      'Hoy: 2 estudios, 1 entreno, entrega de Física y 1 tarea de reto',
    );
    expect(
      es.morningSummaryBody(summary.copyWith(checkIn: true)),
      'Hoy: 2 estudios, 1 entreno, entrega de Física y 1 tarea de reto. '
      'Cuéntanos también qué tal estás.',
    );
    expect(
      es.morningSummaryBody(
        const ReminderDaySummary(
          classes: 1,
          deadlines: [ReminderSummaryDeadline(exam: true)],
        ),
      ),
      'Hoy: 1 clase y un examen',
    );
    // Nunca va vacío (el servidor solo lo manda si hay algo).
    expect(
      es.morningSummaryBody(const ReminderDaySummary()),
      'Mira lo que trae hoy.',
    );
    expect(
      en.morningSummaryBody(summary),
      'Today: 2 study sessions, 1 workout, Física assignment and '
      '1 challenge task',
    );
  });

  test('los avisos mencionan las tareas de reto que van con ellos', () {
    expect(
      es.withTasks('Física empieza a las 17:00', const [task]),
      'Física empieza a las 17:00 · tarea «Repasar tema 3» del reto '
      '«Aprobar Física»',
    );
    expect(
      es.withTasks('Práctica', const [
        ReminderTask(challengeId: 'c', challengeTitle: 'Aprobar Física'),
      ]),
      'Práctica · reto «Aprobar Física»',
    );
    expect(
      es.withTasks('Práctica', [task, task.copyWith(title: 'Hacer test')]),
      'Práctica · tareas de reto «Repasar tema 3» y «Hacer test»',
    );
    expect(es.withTasks('Práctica', const []), 'Práctica');
  });

  test('nombre de reserva según el tipo y antelación sin cifra fija', () {
    expect(
      es.blockBody(ReminderKind.sportBlock, null, five),
      'Tu entreno empieza a las 17:00',
    );
    expect(
      es.wellbeingTitle(ReminderKind.classSoon, name: 'Física', minutes: 30),
      'Física en 30 min',
    );
    expect(es.wellbeingTitle(ReminderKind.classSoon), 'Tu clase');
    expect(es.startAction(ReminderKind.personalEvent), 'Empezar');
  });
}
