import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// «Fecha de nacimiento (opcional)» (ADR 0036): campo pulsable que abre el
/// calendario en la vista de años y, con fecha, «Quitar». La edad se calcula
/// sola; la validación final (no futura, edad razonable) es del servidor, y el
/// calendario ya limita los años para no ofrecer fechas imposibles. Se usa en
/// Editar cuenta y en el primer paso del onboarding.
class BirthDateField extends StatefulWidget {
  const BirthDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.now,
  });

  final DateTime? value;

  /// Nulo: quitar la fecha.
  final ValueChanged<DateTime?> onChanged;

  /// Para los tests; por defecto, hoy.
  final DateTime? now;

  /// Límites del calendario: copian los del servidor (`BirthDate`), que es
  /// quien manda; aquí solo evitan ofrecer fechas que se rechazarían.
  static const minAge = 14;
  static const maxAge = 100;

  @override
  State<BirthDateField> createState() => _BirthDateFieldState();
}

class _BirthDateFieldState extends State<BirthDateField> {
  /// Al quitar la fecha el botón desaparece: el foco vuelve al campo.
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pick(BuildContext context) async {
    const minAge = BirthDateField.minAge;
    const maxAge = BirthDateField.maxAge;
    final value = widget.value;
    final today = widget.now ?? DateTime.now();
    final last = DateTime(today.year - minAge, today.month, today.day);
    final first = DateTime(today.year - maxAge, today.month, today.day);
    final wanted = value ?? DateTime(today.year - 20, today.month, today.day);
    final initial = wanted.isAfter(last)
        ? last
        : wanted.isBefore(first)
        ? first
        : wanted;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      initialDatePickerMode: DatePickerMode.year,
      helpText: context.localizations.profileBirthDateLabel,
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final date = widget.value;
    final text = date == null
        ? l10n.profileBirthDateEmpty
        : DateFormat.yMMMMd(l10n.localeName).format(date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFocusOutline(
          child: ListTile(
            focusNode: _focus,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cake_outlined),
            title: Text(l10n.profileBirthDateLabel),
            subtitle: Text(
              text,
              style: context.textStyles.bodyLarge?.copyWith(
                color: date == null
                    ? context.colors.onSurfaceVariant
                    : context.colors.onSurface,
              ),
            ),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () => _pick(context),
          ),
        ),
        Text(
          l10n.profileBirthDateHint,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (date != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () {
                widget.onChanged(null);
                _focus.requestFocus();
              },
              icon: const Icon(AppIcons.close, size: TokensSize.iconS),
              label: Text(l10n.profileBirthDateRemove),
            ),
          ),
      ],
    );
  }
}
