import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Un destino de la barra de pestañas (icono sin elegir, elegido y nombre).
typedef ShellDestination = ({IconData icon, IconData selected, String label});

/// Barra inferior de [MainShellPage] en el móvil: cinco pestañas en un ancho
/// estrecho. Las etiquetas crecen con el texto hasta 1,3×, pero nunca tanto que
/// la más larga se parta a mitad de palabra («Calendar/io» a 360 px y 200 %):
/// el tamaño se ajusta al hueco de cada pestaña. El tooltip (mantener pulsado)
/// dice siempre el nombre entero.
class ShellNavigationBar extends StatelessWidget {
  const ShellNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Mayor escala (entre 1 y [TokensLayout.largeTextScale]) a la que la
  /// etiqueta más larga cabe en una línea dentro de su hueco. Se mide con el
  /// estilo de la pestaña elegida y el de las demás, y vale el más ancho.
  double _fittingScale(BuildContext context, double width) {
    const maxScale = TokensLayout.largeTextScale;
    final theme = NavigationBarTheme.of(context).labelTextStyle;
    final styles = [
      theme?.resolve({}) ?? context.textStyles.labelMedium,
      theme?.resolve({WidgetState.selected}) ?? context.textStyles.labelMedium,
    ];
    final slot = width / destinations.length - TokensSpacing.s;
    var widest = 0.0;
    for (final d in destinations) {
      for (final style in styles) {
        final painter = TextPainter(
          text: TextSpan(text: d.label, style: style),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout();
        if (painter.width > widest) widest = painter.width;
        painter.dispose();
      }
    }
    if (widest <= 0) return maxScale;
    return (slot / widest).clamp(1.0, maxScale).toDouble();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: context.colors.outlineVariant)),
    ),
    child: AppFocusGroup(
      child: LayoutBuilder(
        builder: (context, constraints) => MediaQuery.withClampedTextScaling(
          maxScaleFactor: _fittingScale(context, constraints.maxWidth),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: AppNavFocusRing(child: Icon(d.icon)),
                  selectedIcon: AppNavFocusRing(child: Icon(d.selected)),
                  label: d.label,
                  tooltip: d.label,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
