import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_focus_outline.dart';

/// Título de sección (encabezado accesible) con acción opcional a la derecha.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionExpanded,
    this.focusNode,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Si la acción despliega o pliega contenido («Ver todas» / «Ver menos»),
  /// su estado: el lector de pantalla lo anuncia como desplegado o plegado.
  final bool? actionExpanded;

  /// Para llevar aquí el foco tras quitar lo que había encima (WCAG 2.4.3).
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: Row(
        children: [
          // Encabezado real para lectores de pantalla: permite saltar de
          // sección en sección.
          Expanded(
            flex: 3,
            child: _anchored(
              Semantics(
                header: true,
                child: Text(title, style: context.textStyles.titleMedium),
              ),
            ),
          ),
          // Hasta 2/5 del ancho y pegada a la derecha: con el texto muy
          // grande se parte en dos líneas en lugar de empujar el título.
          if (label != null)
            Flexible(
              flex: 2,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: MergeSemantics(
                  child: Semantics(
                    expanded: actionExpanded,
                    child: TextButton(
                      onPressed: onAction,
                      child: Text(label, textAlign: TextAlign.end),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _anchored(Widget header) {
    final node = focusNode;
    return node == null
        ? header
        : AppFocusAnchor(focusNode: node, child: header);
  }
}
