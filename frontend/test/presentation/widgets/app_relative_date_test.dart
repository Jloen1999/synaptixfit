import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations_es.dart';
import 'package:synaptixfit/presentation/widgets/app_relative_date.dart';

/// Una fecha próxima se dice igual en toda la app (revisión del 25 nov):
/// «Hoy · 17:00», «Mañana · 9:00», «jue 26 · 9:00»; nunca «mié 17:00» si
/// hoy es miércoles.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final l10n = AppLocalizationsEs();
  // Miércoles 25 de noviembre de 2026, por la tarde.
  final now = DateTime(2026, 11, 25, 16, 30);

  test('hoy y mañana con palabras; esta semana, día y número', () {
    expect(
      AppRelativeDate.dayTime(l10n, DateTime(2026, 11, 25, 17), now: now),
      'Hoy · 17:00',
    );
    expect(
      AppRelativeDate.dayTime(l10n, DateTime(2026, 11, 26, 9), now: now),
      'Mañana · 9:00',
    );
    expect(
      AppRelativeDate.dayTime(l10n, DateTime(2026, 11, 27, 9), now: now),
      'vie 27 · 9:00',
    );
  });

  test('más allá de una semana o ya pasado, con el mes', () {
    expect(
      AppRelativeDate.day(l10n, DateTime(2026, 12, 7), now: now),
      'lun 7 dic',
    );
    expect(
      AppRelativeDate.day(l10n, DateTime(2026, 11, 23), now: now),
      'lun 23 nov',
    );
  });

  test('el próximo entreno: «Hoy», «Mañana» o el día entero', () {
    expect(AppRelativeDate.longDay(l10n, now, now: now), 'Hoy');
    expect(
      AppRelativeDate.longDay(l10n, DateTime(2026, 11, 30), now: now),
      'Lunes 30 nov',
    );
  });

  test('el cambio de hora no cambia la cuenta de días', () {
    // El 25 de octubre de 2026 el día dura 25 h en Europa; el 29 de marzo, 23.
    expect(
      AppRelativeDate.day(
        l10n,
        DateTime(2026, 3, 30, 8),
        now: DateTime(2026, 3, 29, 1),
      ),
      'Mañana',
    );
    expect(
      AppRelativeDate.day(
        l10n,
        DateTime(2026, 10, 26, 0, 30),
        now: DateTime(2026, 10, 25, 23),
      ),
      'Mañana',
    );
  });
}
