import 'package:flutter/material.dart';

/// Grupo de foco del teclado: lo que hay dentro se recorre entero con el
/// Tabulador antes de pasar al siguiente grupo. Se usa en la raíz de la app,
/// en la navegación del armazón, en cada columna de las maquetas de varias
/// columnas y, vía `AppScrollBehavior`, en cada zona desplazable.
class AppFocusGroup extends StatelessWidget {
  const AppFocusGroup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      FocusTraversalGroup(policy: appFocusTraversalPolicy(), child: child);
}

/// Orden de lectura (el de Flutter por defecto) que, además, desplaza la
/// pantalla en los dos sentidos para que el elemento enfocado se vea.
ReadingOrderTraversalPolicy appFocusTraversalPolicy() =>
    ReadingOrderTraversalPolicy(requestFocusCallback: revealFocusedNode);

/// Enfoca [node] y lo hace visible tanto si queda por encima como por debajo
/// de lo que se ve (WCAG 2.4.11).
///
/// Por qué: la política por defecto solo desplaza hacia abajo al avanzar y
/// hacia arriba al retroceder. En dos columnas, pasar del final de la
/// izquierda al principio de la derecha (o volver del riel al contenido)
/// dejaba el foco fuera de la pantalla.
void revealFocusedNode(
  FocusNode node, {
  ScrollPositionAlignmentPolicy? alignmentPolicy,
  double? alignment,
  Duration? duration,
  Curve? curve,
}) {
  node.requestFocus();
  final context = node.context;
  if (context == null) return;
  // Cada política solo actúa en su sentido: juntas, el desplazamiento mínimo.
  for (final policy in const [
    ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
  ]) {
    Scrollable.ensureVisible(
      context,
      alignmentPolicy: policy,
      duration: duration ?? Duration.zero,
      curve: curve ?? Curves.ease,
    );
  }
}
