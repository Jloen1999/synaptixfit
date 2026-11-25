import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Un texto (o un bloque) con un botón al lado que baja a su propia línea,
/// alineado al final, si no caben los dos (320 px, texto al 200 %; WCAG
/// 1.4.10). Al lado solo si al texto le queda al menos lo que ocupa el botón:
/// así ni el texto se parte letra a letra ni el botón en dos líneas. El ancho
/// del botón se mide con su estilo real ([actionStyle]; si no, el del tema de
/// `TextButton`).
class AppTextWithAction extends StatelessWidget {
  const AppTextWithAction({
    super.key,
    required this.child,
    required this.action,
    required this.actionLabel,
    this.actionIcon = false,
    this.actionStyle,
  });

  final Widget child;
  final Widget action;

  /// Texto visible del botón, para medirlo.
  final String actionLabel;

  /// El botón lleva icono delante del texto.
  final bool actionIcon;
  final ButtonStyle? actionStyle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionWidth = context.buttonWidth(
          actionLabel,
          actionStyle ?? TextButtonTheme.of(context).style,
          icon: actionIcon,
        );
        final room = constraints.maxWidth - TokensSpacing.s - actionWidth;
        if (room >= actionWidth) {
          return Row(
            children: [
              Expanded(child: child),
              const SizedBox(width: TokensSpacing.s),
              action,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child,
            const SizedBox(height: TokensSpacing.xs),
            Align(alignment: AlignmentDirectional.centerEnd, child: action),
          ],
        );
      },
    );
  }
}
