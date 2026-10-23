import 'package:flutter/widgets.dart';

import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Limita el ancho del contenido en pantallas grandes (web, tablet).
class ChallengeContentWidth extends StatelessWidget {
  const ChallengeContentWidth({super.key, required this.child});

  static const maxWidth = TokensLayout.contentMaxWidth;

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AppContentWidth(maxWidth: maxWidth, child: child);
}
