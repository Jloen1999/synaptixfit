import 'package:flutter/widgets.dart';

/// Envuelve una gráfica para que los lectores de pantalla lean un resumen
/// textual en lugar de sus trazos (WCAG 1.1.1). Lo usan `ChartCard` y las
/// gráficas del panel de administración.
class AppChartSummary extends StatelessWidget {
  const AppChartSummary({
    super.key,
    required this.summary,
    required this.child,
  });

  /// Frase con los valores clave (periodo, máximos, último valor…).
  final String summary;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: summary,
      // Los ejes y puntos sueltos de la gráfica no aportan nada leídos uno a uno.
      child: ExcludeSemantics(child: child),
    );
  }
}
