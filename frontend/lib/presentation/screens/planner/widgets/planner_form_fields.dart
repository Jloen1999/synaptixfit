import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'planner_visuals.dart';

/// Campo de solo lectura que abre un selector (fecha u hora) al tocarlo.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;

  /// `null` deshabilita el campo.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppFocusOutline(
      borderRadius: BorderRadius.circular(TokensRadius.m),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            enabled: onTap != null,
          ),
          child: Text(value, style: context.textStyles.bodyLarge),
        ),
      ),
    );
  }
}

/// Mensaje en línea (error o aviso) dentro de una hoja inferior, donde un
/// SnackBar quedaría oculto.
class InlineMessage extends StatelessWidget {
  const InlineMessage({super.key, required this.message, this.isError = true});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? context.colors.error : context.palette.warning;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(TokensSpacing.s),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(TokensRadius.m),
        ),
        child: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.info_outline_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: Text(message, style: context.textStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selección de días de la semana (L-D) con chips.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// 1 = lunes … 7 = domingo.
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TokensSpacing.xs,
      runSpacing: TokensSpacing.xs,
      children: [
        for (var d = 1; d <= 7; d++)
          Tooltip(
            message: PlannerFormats.weekdayName(d),
            child: FilterChip(
              label: Text(PlannerFormats.weekdayInitials(d)),
              selected: selected.contains(d),
              showCheckmark: false,
              onSelected: (on) {
                final next = {...selected};
                on ? next.add(d) : next.remove(d);
                onChanged(next);
              },
            ),
          ),
      ],
    );
  }
}

/// Pide fecha con el selector en español.
Future<DateTime?> pickPlannerDate(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
}) {
  final now = DateTime.now();
  final firstDate = first ?? DateTime(now.year - 1);
  final lastDate = last ?? DateTime(now.year + 2, 12, 31);
  var initialDate = initial;
  if (initialDate.isBefore(firstDate)) initialDate = firstDate;
  if (initialDate.isAfter(lastDate)) initialDate = lastDate;
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    locale: const Locale('es'),
  );
}

/// Pide una hora y la devuelve en minutos desde medianoche.
Future<int?> pickPlannerTime(BuildContext context, int initialMinutes) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: initialMinutes ~/ 60,
      minute: initialMinutes % 60,
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  return picked == null ? null : picked.hour * 60 + picked.minute;
}
