import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';
import 'app_focus_outline.dart';

/// Zona pulsable dentro de una tarjeta que tiene además otras acciones (autor,
/// «me gusta», marcar como hecha…). La tarjeta no es pulsable entera: así no
/// hay toques anidados y cada acción es hermana de las demás. El lector oye la
/// zona como un botón con todo su contenido (o con [semanticLabel]); con el
/// teclado lleva el anillo de foco de [AppFocusOutline].
class AppCardTapArea extends StatelessWidget {
  const AppCardTapArea({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(TokensRadius.m)),
    this.semanticLabel,
    this.semanticHint,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  /// Sustituye al contenido para el lector de pantalla.
  final String? semanticLabel;

  /// Qué hace el toque («Abrir publicación», «Editar entrega») cuando el
  /// contenido no lo dice.
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    // Con etiqueta propia se excluye solo el contenido (no el InkWell): así se
    // conservan la acción de toque y el foco en web.
    final content = semanticLabel == null
        ? child
        : ExcludeSemantics(child: child);
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: semanticLabel,
        hint: semanticHint,
        child: AppFocusOutline(
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            // Objetivo táctil mínimo aunque el contenido sea una sola línea.
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: TokensLayout.minTouchTarget,
              ),
              child: Padding(padding: padding, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
