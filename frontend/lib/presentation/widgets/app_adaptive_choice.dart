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
    this.label,
  });

  /// Nombre del grupo («Quién puede verlo»): se pinta encima y lo anuncia el
  /// lector de pantalla al entrar en las opciones.
  final String? label;

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final IconData Function(T value) iconOf;

  /// Nulo: solo lectura.
  final ValueChanged<T>? onChanged;

  /// Opciones que ahora no se pueden elegir (por defecto, todas se pueden).
  final bool Function(T value)? enabledOf;

  /// Por qué alguna opción está bloqueada: texto visible bajo los botones o
  /// bajo la opción en la lista (un tooltip no se ve en el móvil).
  final String? disabledHint;

  /// Explicación corta de cada opción: bajo cada una en la lista y, con
  /// botones, la de la opción elegida bajo ellos.
  final String Function(T value)? hintOf;

  bool _enabled(T value) => enabledOf?.call(value) ?? true;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final perOption = constraints.maxWidth / values.length;
      final stacked =
          context.largeText || perOption < TokensLayout.segmentMinWidth;
      final choice = stacked ? _list(context) : _segments(context);
      final title = label;
      if (title == null) return choice;
      return Semantics(
        container: true,
        label: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Text(title, style: context.textStyles.titleSmall),
            ),
            const SizedBox(height: TokensSpacing.xs),
            choice,
          ],
        ),
      );
    },
  );

  Widget _segments(BuildContext context) {
    final blocked = disabledHint != null && values.any((v) => !_enabled(v));
    final hint = hintOf?.call(selected);
    final notes = [?hint, if (blocked) disabledHint!];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
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
        ),
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(top: TokensSpacing.xs),
            child: Text(
              note,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

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
              // El círculo al final, como en el resto de ajustes de la app.
              controlAffinity: ListTileControlAffinity.trailing,
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
