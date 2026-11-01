import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Barra de avance (p. ej. del ciclo de una rutina o de un reto) con su texto
/// al lado («6/12 días»); el lector oye ese mismo texto. La comparten Rutinas,
/// Inicio y Retos; [color] (por defecto `primary`) permite el acento del tipo.
class AppCycleProgress extends StatelessWidget {
  const AppCycleProgress({
    super.key,
    required this.progress,
    required this.label,
    this.color,
    this.semanticsLabel,
  });

  /// Entre 0 y 1.
  final double progress;
  final String label;
  final Color? color;

  /// Lo que oye el lector si el texto visible no basta («Progreso del 45 %»).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TokensRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              color: color ?? context.colors.primary,
              backgroundColor: context.colors.surfaceContainerHigh,
              semanticsLabel: semanticsLabel ?? label,
            ),
          ),
        ),
        const SizedBox(width: TokensSpacing.s),
        ExcludeSemantics(
          child: Text(label, style: context.textStyles.labelLarge),
        ),
      ],
    );
  }
}
