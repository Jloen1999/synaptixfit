import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

/// Dibuja un contorno marcado sobre [child] cuando algo dentro tiene el foco
/// del teclado (WCAG 2.4.7). Para controles propios cuyo resaltado de foco por
/// defecto (un velo leve) no se distingue: `InkWell` propios y `ListTile`
/// pulsables. El radio por defecto es el de las filas de lista del tema.
class AppFocusOutline extends StatefulWidget {
  const AppFocusOutline({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(TokensRadius.m)),
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<AppFocusOutline> createState() => _AppFocusOutlineState();
}

class _AppFocusOutlineState extends State<AppFocusOutline> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    // Solo observa: no es enfocable ni aparece en el orden del Tabulador.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: _focused
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: TokensSize.focusRing,
                )
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Anillo de foco de los destinos de la barra inferior y del riel (WCAG
/// 2.4.7): Material solo pinta un velo casi invisible sobre `navigationBar`.
/// Envuelve el icono del destino (en `MainShellPage`) y escucha el foco del
/// destino que lo contiene; dibuja un óvalo del tamaño del indicador en
/// `onSurface` (más de 3:1 con la barra, ver `contrast_test.dart`) sin cambiar
/// la maqueta.
class AppNavFocusRing extends StatelessWidget {
  const AppNavFocusRing({super.key, required this.child, this.rail = false});

  final Widget child;

  /// En el riel el indicador es más estrecho (56 × 32) que en la barra
  /// inferior (64 × 32); el icono mide 24.
  final bool rail;

  @override
  Widget build(BuildContext context) {
    // El nodo más cercano es el del destino (su InkWell). `Focus.maybeOf`
    // depende de él, así que este widget se repinta al ganar o perder el foco.
    final focused = Focus.maybeOf(context)?.hasPrimaryFocus ?? false;
    final dx = rail ? TokensSpacing.m : TokensSpacing.ml;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        if (focused)
          Positioned(
            left: -dx,
            right: -dx,
            top: -TokensSpacing.xs,
            bottom: -TokensSpacing.xs,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('app-nav-focus-ring'),
                decoration: ShapeDecoration(
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: TokensSize.focusRing,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
