import 'package:flutter/material.dart';

import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Limita el ancho del contenido en pantallas grandes (web, tablet).
class TrainingContent extends StatelessWidget {
  const TrainingContent({
    super.key,
    required this.child,
    this.maxWidth = TokensLayout.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) =>
      AppContentWidth(maxWidth: maxWidth, child: child);
}
