import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Rejilla de accesos rápidos (Inicio, Rutinas): todos en una fila y, si a
/// cada uno le tocarían menos de [minTileWidth] (escalado con el texto), en
/// filas de la mitad. Así las etiquetas no se cortan con el texto al 200 %.
class AppTileGrid extends StatelessWidget {
  const AppTileGrid({
    super.key,
    required this.children,
    this.minTileWidth = 80,
    this.spacing = TokensSpacing.s,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = context.scaled(minTileWidth);
        var columns = children.length;
        while (columns > 1 &&
            (constraints.maxWidth - spacing * (columns - 1)) / columns <
                minWidth) {
          columns = (columns / 2).ceil();
        }
        final gap = SizedBox(width: spacing, height: spacing);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i += columns) ...[
              if (i > 0) gap,
              // Las tarjetas de una fila miden lo mismo aunque una etiqueta
              // ocupe dos líneas.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = i; j < i + columns; j++) ...[
                      if (j > i) gap,
                      Expanded(
                        child: j < children.length
                            ? children[j]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
