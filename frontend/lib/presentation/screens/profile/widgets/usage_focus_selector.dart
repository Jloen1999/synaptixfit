import 'package:flutter/material.dart';

import '../../../../domain/enums/usage_focus.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Elección del enfoque de uso (estudios, deporte o ambos) con tres tarjetas
/// seleccionables. Se usa en el onboarding y al editar la cuenta.
class UsageFocusSelector extends StatelessWidget {
  const UsageFocusSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final UsageFocus? value;
  final ValueChanged<UsageFocus> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final options = [
      (
        UsageFocus.both,
        Icons.all_inclusive_rounded,
        l10n.profileFocusBoth,
        l10n.profileFocusBothHint,
        context.colors.onSurface,
      ),
      (
        UsageFocus.academic,
        Icons.school_outlined,
        l10n.profileFocusAcademic,
        l10n.profileFocusAcademicHint,
        context.palette.study,
      ),
      (
        UsageFocus.fitness,
        Icons.fitness_center_rounded,
        l10n.profileFocusFitness,
        l10n.profileFocusFitnessHint,
        context.palette.sessions,
      ),
    ];
    // Grupo con nombre: el lector anuncia «Uso de la app» y luego cada opción
    // como radio marcado o sin marcar.
    return Semantics(
      container: true,
      label: l10n.profileFocusTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (focus, icon, title, hint, color) in options)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.s),
              child: _Option(
                icon: icon,
                title: title,
                hint: hint,
                color: color,
                selected: value == focus,
                onTap: () => onChanged(focus),
              ),
            ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.hint,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.l),
        child: Material(
          color: selected
              ? color.withValues(alpha: AppPill.tintAlpha)
              : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TokensRadius.l),
            side: BorderSide(
              color: selected ? color : colors.outlineVariant,
              width: selected ? TokensSize.focusRing : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(TokensRadius.l),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(TokensSpacing.m),
              child: Row(
                children: [
                  Icon(icon, color: color, size: TokensSize.iconM),
                  const SizedBox(width: TokensSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.textStyles.titleMedium),
                        Text(
                          hint,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected ? color : colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
