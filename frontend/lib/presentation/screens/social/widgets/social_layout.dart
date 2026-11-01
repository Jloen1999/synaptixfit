import 'package:flutter/material.dart';

import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Ancho máximo del contenido del módulo en pantallas grandes.
const socialMaxContentWidth = TokensLayout.readingMaxWidth;

/// Centra el contenido y limita su ancho en web y tabletas.
class SocialContentWidth extends StatelessWidget {
  const SocialContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AppContentWidth(maxWidth: socialMaxContentWidth, child: child);
}

/// Esqueleto de carga de una lista de tarjetas con el ancho del módulo.
class SocialListSkeleton extends StatelessWidget {
  const SocialListSkeleton({super.key, this.itemHeight = 160, this.count = 4});

  final double itemHeight;
  final int count;

  @override
  Widget build(BuildContext context) => SocialContentWidth(
    child: AppSkeletonList(count: count, height: itemHeight),
  );
}
