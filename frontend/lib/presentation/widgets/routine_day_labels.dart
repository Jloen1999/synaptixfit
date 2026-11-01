import 'package:intl/intl.dart';

import '../l10n/gen_l10n/app_localizations.dart';

/// Textos de un día de rutina que comparten Rutinas e Inicio: el número del
/// día es el día de la semana preferido y la fecha prevista la da el servidor.

/// Nombre del día de la semana (1 = lunes … 7 = domingo).
String weekdayName(AppLocalizations l10n, int dayNumber) => switch (dayNumber) {
  1 => l10n.trainingWeekday1,
  2 => l10n.trainingWeekday2,
  3 => l10n.trainingWeekday3,
  4 => l10n.trainingWeekday4,
  5 => l10n.trainingWeekday5,
  6 => l10n.trainingWeekday6,
  _ => l10n.trainingWeekday7,
};

/// Fecha prevista de un día de rutina: «Miércoles 5 nov» (en el idioma de la app).
String scheduledDayLabel(AppLocalizations l10n, DateTime date) =>
    toBeginningOfSentenceCase(
      DateFormat('EEEE d MMM', l10n.localeName).format(date),
    );

/// Línea del próximo día: «Miércoles 5 nov · Semana 2 de 4 · Tirón». Sin
/// nombre propio, el día de la semana ya va en la fecha y no se repite.
String nextDayHeadline(
  AppLocalizations l10n, {
  required DateTime? date,
  required int weekNumber,
  required int totalWeeks,
  required int dayNumber,
  String? dayName,
}) {
  final name = dayName?.trim();
  return [
    if (date != null)
      scheduledDayLabel(l10n, date)
    else
      weekdayName(l10n, dayNumber),
    l10n.trainingWeekOfTotal(weekNumber, totalWeeks),
    if (name != null && name.isNotEmpty) name,
  ].join(' · ');
}

/// Aviso de retraso: «Atrasado: tocaba el lunes 3 nov».
String overdueSinceLabel(AppLocalizations l10n, DateTime date) =>
    l10n.trainingOverdueSince(
      DateFormat('EEEE d MMM', l10n.localeName).format(date),
    );
