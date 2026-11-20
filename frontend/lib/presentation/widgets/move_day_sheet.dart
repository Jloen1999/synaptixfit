import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.g.dart';

/// Elegir otro día a la misma hora (Inicio y la ficha de un evento del
/// calendario, ADR 0059 y 0060): hoy (si aún no ha pasado esa hora),
/// mañana, los cinco siguientes y «Otro día…» con el calendario. Devuelve el
/// día elegido o nulo.
Future<DateTime?> showMoveDaySheet(
  BuildContext context, {
  required DateTime from,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final timeToday = DateTime(
    now.year,
    now.month,
    now.day,
    from.hour,
    from.minute,
  );
  final days = [
    if (timeToday.isAfter(now)) today,
    for (var i = 1; i <= 6; i++) DateTime(now.year, now.month, now.day + i),
  ];
  return showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) {
      final l10n = sheet.localizations;
      final time = DateFormat.Hm(l10n.localeName).format(from);
      String label(DateTime d) {
        final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
        final date = DateFormat.MMMMEEEEd(l10n.localeName).format(d);
        return switch (diff) {
          0 => l10n.homeMoveTodayOn(date),
          1 => l10n.homeMoveTomorrowOn(date),
          _ => toBeginningOfSentenceCase(date),
        };
      }

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.m,
            0,
            TokensSpacing.m,
            TokensSpacing.m,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.homeMoveTitle,
                  style: sheet.textStyles.titleMedium,
                ),
              ),
              Text(
                l10n.homeMoveSameTime(time),
                style: sheet.textStyles.bodyMedium?.copyWith(
                  color: sheet.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              for (final d in days) ...[
                OutlinedButton(
                  onPressed: () => Navigator.of(sheet).pop(d),
                  child: Text(label(d)),
                ),
                const SizedBox(height: TokensSpacing.s),
              ],
              OutlinedButton.icon(
                icon: const Icon(AppIcons.calendar),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: sheet,
                    // Hoy solo si aún no ha pasado esa hora.
                    firstDate: days.first,
                    lastDate: DateTime(today.year + 1, today.month, today.day),
                    initialDate: days.first,
                  );
                  if (picked != null && sheet.mounted) {
                    Navigator.of(sheet).pop(picked);
                  }
                },
                label: Text(l10n.homeMoveOtherDay),
              ),
            ],
          ),
        ),
      );
    },
  );
}
