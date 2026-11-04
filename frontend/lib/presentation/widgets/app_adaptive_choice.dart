import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_focus_outline.dart';

/// Elegir una opción entre pocas (p. ej. quién puede ver algo). Con sitio de
/// sobra se ve como botones segmentados; con texto grande o una pantalla
/// estrecha pasa a una lista de opciones, para que ninguna etiqueta se corte
/// (en francés y portugués los nombres son largos).
class AppAdaptiveChoice<T> extends StatelessWidget {
  const AppAdaptiveChoice({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.iconOf,
    this.onChanged,
    this.enabledOf,
    this.disabledHint,
    this.hintOf,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final IconData Function(T value) iconOf;

  /// Nulo: solo lectura.
  final ValueChanged<T>? onChanged;

  /// Opciones que ahora no se pueden elegir (por defecto, todas se pueden).
  final bool Function(T value)? enabledOf;

  /// Por qué una opción está bloqueada (tooltip en los botones; texto bajo
  /// la opción en la lista).
  final String? disabledHint;

  /// Explicación corta de cada opción, solo en la lista.
  final String Function(T value)? hintOf;

  bool _enabled(T value) => enabledOf?.call(value) ?? true;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final perOption = constraints.maxWidth / values.length;
      final stacked =
          context.largeText || perOption < TokensLayout.segmentMinWidth;
      return stacked ? _list(context) : _segments();
    },
  );

  Widget _segments() => SizedBox(
    width: double.infinity,
    child: SegmentedButton<T>(
      showSelectedIcon: false,
      segments: [
        for (final v in values)
          ButtonSegment<T>(
            value: v,
            enabled: _enabled(v),
            tooltip: _enabled(v) ? null : disabledHint,
            icon: Icon(iconOf(v)),
            label: Text(labelOf(v)),
          ),
      ],
      selected: {selected},
      onSelectionChanged: onChanged == null ? null : (s) => onChanged!(s.first),
    ),
  );

  Widget _list(BuildContext context) => RadioGroup<T>(
    groupValue: selected,
    onChanged: (v) {
      if (v != null && onChanged != null) onChanged!(v);
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final v in values)
          AppFocusOutline(
            child: RadioListTile<T>(
              value: v,
              enabled: onChanged != null && _enabled(v),
              contentPadding: EdgeInsets.zero,
              secondary: Icon(iconOf(v)),
              title: Text(labelOf(v)),
              subtitle: switch ((_enabled(v), hintOf)) {
                (false, _) when disabledHint != null => Text(disabledHint!),
                (true, final hint?) => Text(hint(v)),
                _ => null,
              },
            ),
          ),
      ],
    ),
  );
}
