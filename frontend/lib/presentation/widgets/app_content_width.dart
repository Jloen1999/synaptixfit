import 'package:flutter/widgets.dart';

import '../theme/tokens.g.dart';

/// Centra el contenido de una página y limita su ancho en web y tableta.
/// Todos los módulos lo usan para que las pestañas se alineen igual.
class AppContentWidth extends StatelessWidget {
  const AppContentWidth({
    super.key,
    required this.child,
    this.maxWidth = TokensLayout.contentMaxWidth,
  });

  /// Formularios y textos largos: líneas más cortas, más fáciles de leer.
  const AppContentWidth.reading({super.key, required this.child})
    : maxWidth = TokensLayout.readingMaxWidth;

  /// Paneles de varias columnas (Inicio, administración).
  const AppContentWidth.wide({super.key, required this.child})
    : maxWidth = TokensLayout.wideMaxWidth;

  final Widget child;
  final double maxWidth;

  /// Mide lo que su contenido (heightFactor 1): sin él, en una barra inferior
  /// (`bottomNavigationBar`) se estiraba a toda la pantalla y tapaba la página.
  /// Las listas siguen ocupando todo el alto, como antes.
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
