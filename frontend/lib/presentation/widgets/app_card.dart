import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

/// Tarjeta base: borde suave, sin sombra y con toque opcional. Si es pulsable,
/// con el foco del teclado el borde pasa a un anillo marcado (WCAG 2.4.7),
/// igual que los botones del tema.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(TokensSpacing.m),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    // Pulsable entera: se anuncia como un botón con todo su contenido.
    return Semantics(button: widget.onTap != null, child: _card(context));
  }

  Widget _card(BuildContext context) {
    return Card(
      color: widget.color,
      clipBehavior: Clip.antiAlias,
      // Sin foco se usa la forma del tema (borde suave).
      shape: _focused
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TokensRadius.l),
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface,
                width: 2,
              ),
            )
          : null,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );
  }
}
