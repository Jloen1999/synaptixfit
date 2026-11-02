import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Estado de un paso numerado de [AppStepBadge].
enum AppStepState { active, locked, done }

/// Círculo numerado de un paso (explicación del cronómetro, repaso en dos
/// pasos): activo en el color del contenedor primario, bloqueado en neutro y
/// hecho con una marca. Es decorativo: el texto del paso ya lo dice.
class AppStepBadge extends StatelessWidget {
  const AppStepBadge({
    super.key,
    required this.number,
    this.state = AppStepState.active,
  });

  final int number;
  final AppStepState state;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (state) {
      AppStepState.active => (
        context.colors.primaryContainer,
        context.colors.onPrimaryContainer,
      ),
      AppStepState.locked => (
        context.colors.surfaceContainerHigh,
        context.colors.onSurfaceVariant,
      ),
      AppStepState.done => (context.palette.success, context.colors.surface),
    };
    // Crece con el tamaño de letra para que la cifra no se salga del círculo.
    final size = context.scaled(TokensSize.stepBadge);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: state == AppStepState.done
            ? Icon(
                Icons.check_rounded,
                size: TokensSize.iconXs,
                color: foreground,
              )
            : Text(
                '$number',
                style: context.textStyles.labelLarge?.copyWith(
                  color: foreground,
                ),
              ),
      ),
    );
  }
}
