import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Elegir una opción corta (prioridad, dificultad, tipo de clase) sin icono.
/// Con sitio se ve como botones segmentados; con el texto grande o poco ancho
/// pasa a chips que bajan de fila, para que ninguna etiqueta se corte. Si
/// [allowEmpty], tocar la elegida la quita. Para opciones con icono y
/// explicación, [AppAdaptiveChoice].
class AppSegmentedChoice<T extends Object> extends StatelessWidget {
  const AppSegmentedChoice({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.allowEmpty = false,
  });

  /// Nombre del grupo («Prioridad»): se pinta encima y el lector lo anuncia
  /// al entrar en las opciones.
  final String label;
  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final ValueChanged<T?> onChanged;
  final bool allowEmpty;

  void _tap(T value) =>
      onChanged(allowEmpty && value == selected ? null : value);

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(label, style: context.textStyles.labelLarge),
        ),
        const SizedBox(height: TokensSpacing.xs),
        _choices(context),
      ],
    ),
  );

  Widget _choices(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final perOption = constraints.maxWidth / values.length;
      if (context.largeText || perOption < TokensLayout.segmentMinWidth) {
        return Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.s,
          children: [
            for (final v in values)
              ChoiceChip(
                label: Text(labelOf(v)),
                selected: v == selected,
                onSelected: (_) => _tap(v),
              ),
          ],
        );
      }
      return SizedBox(
        width: double.infinity,
        child: SegmentedButton<T>(
          showSelectedIcon: false,
          emptySelectionAllowed: allowEmpty,
          segments: [
            for (final v in values)
              ButtonSegment<T>(value: v, label: Text(labelOf(v))),
          ],
          selected: {?selected},
          onSelectionChanged: (s) => onChanged(s.isEmpty ? null : s.first),
        ),
      );
    },
  );
}
