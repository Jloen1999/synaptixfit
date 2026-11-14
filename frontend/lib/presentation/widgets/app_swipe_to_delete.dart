import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.g.dart';

/// Fila que se elimina deslizándola hacia el inicio (vocabulario §4: borrar
/// no ocupa sitio en cada fila). Asoma el verbo y la papelera, no solo color,
/// y [semanticLabel] da la misma acción al lector de pantalla. Quien la usa
/// muestra el aviso con «Deshacer» en [onDelete].
class AppSwipeToDelete extends StatelessWidget {
  const AppSwipeToDelete({
    super.key,
    required this.itemKey,
    required this.label,
    required this.semanticLabel,
    required this.onDelete,
    required this.child,
    this.enabled = true,
  });

  final Key itemKey;

  /// Verbo que asoma al deslizar («Eliminar»).
  final String label;

  /// Acción para el lector, con el nombre de la fila («Eliminar «Series»»).
  final String semanticLabel;
  final VoidCallback onDelete;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    // Nodo propio: sin él, la acción subiría a la lista y no a la fila.
    container: true,
    customSemanticsActions: enabled
        ? {CustomSemanticsAction(label: semanticLabel): onDelete}
        : null,
    child: Dismissible(
      key: itemKey,
      direction: enabled ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: (_) => onDelete(),
      background: AppDeleteSwipeBackground(label: label),
      child: child,
    ),
  );
}

/// Fondo que asoma al deslizar una fila para eliminarla: icono y verbo.
class AppDeleteSwipeBackground extends StatelessWidget {
  const AppDeleteSwipeBackground({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.errorContainer,
      borderRadius: BorderRadius.circular(TokensRadius.l),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.l),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              label,
              style: context.textStyles.labelLarge?.copyWith(
                color: context.colors.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(width: TokensSpacing.s),
          Icon(AppIcons.delete, color: context.colors.onErrorContainer),
        ],
      ),
    ),
  );
}
