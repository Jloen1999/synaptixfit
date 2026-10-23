import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Bloque de carga con la forma del contenido (con brillo animado salvo que
/// se pida reducir el movimiento).
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.height = 72,
    this.width = double.infinity,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final block = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(TokensRadius.l),
      ),
    );
    // El brillo es decorativo: se oculta al lector de pantalla y se quita si
    // el sistema pide reducir el movimiento.
    return ExcludeSemantics(
      child: context.reduceMotion
          ? block
          : Shimmer.fromColors(
              baseColor: context.colors.surfaceContainer,
              highlightColor: context.colors.surfaceContainerLow,
              child: block,
            ),
    );
  }
}
