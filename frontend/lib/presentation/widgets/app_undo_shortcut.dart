import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ctrl+Z (Cmd+Z en Mac) deshace el último borrado de la pantalla. Así
/// «Deshacer» no depende de llegar con el tabulador al aviso, que va el último
/// en el orden de foco (WCAG 2.1.1).
class AppUndoShortcut extends StatelessWidget {
  const AppUndoShortcut({super.key, required this.onUndo, required this.child});

  final VoidCallback onUndo;
  final Widget child;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true): onUndo,
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): onUndo,
    },
    child: child,
  );
}
