import 'package:intl/intl.dart';

import '../l10n/gen_l10n/app_localizations.dart';

/// Formato único de una fecha próxima («Hoy · 17:00», «Mañana · 9:00»,
/// «jue 26 · 9:00»): lo usan la tarjeta de asignatura, «Lo próximo» de la
/// asignatura, los entrenos de carrera previstos y el próximo día de rutina,
/// así una misma cita no se lee «mié 17:00» en un sitio y «Hoy» en otro.
abstract final class AppRelativeDate {
  /// Días que se nombran solo con el día de la semana y su número («jue 26»):
  /// la semana que viene; más allá se añade el mes («lun 7 dic»).
  static const weekDays = 6;

  /// «Hoy», «Mañana», «jue 26» o, más lejos o ya pasado, «lun 7 dic».
  static String day(AppLocalizations l10n, DateTime date, {DateTime? now}) {
    final days = _daysFrom(date, now);
    if (days == 0) return l10n.commonDateToday;
    if (days == 1) return l10n.commonDateTomorrow;
    final pattern = days > 1 && days <= weekDays ? 'EEE d' : 'EEE d MMM';
    return DateFormat(pattern, l10n.localeName).format(date);
  }

  /// [day] con la hora en el formato del idioma (24 h en es/fr/pt, 12 h en
  /// inglés): «Hoy · 17:00».
  static String dayTime(
    AppLocalizations l10n,
    DateTime date, {
    DateTime? now,
  }) =>
      '${day(l10n, date, now: now)} · '
      '${DateFormat.jm(l10n.localeName).format(date)}';

  /// Como [day], pero con el día de la semana completo si no es hoy ni
  /// mañana («Lunes 30 nov»): la cabecera de un próximo entreno.
  static String longDay(AppLocalizations l10n, DateTime date, {DateTime? now}) {
    final days = _daysFrom(date, now);
    if (days == 0 || days == 1) return day(l10n, date, now: now);
    return toBeginningOfSentenceCase(
      DateFormat('EEEE d MMM', l10n.localeName).format(date),
    );
  }

  /// Días de calendario de hoy a [date] (negativo si ya pasó). En UTC: con
  /// el cambio de hora un día local dura 23 h y `inDays` daría uno menos.
  static int _daysFrom(DateTime date, DateTime? now) {
    final today = now ?? DateTime.now();
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  }
}
