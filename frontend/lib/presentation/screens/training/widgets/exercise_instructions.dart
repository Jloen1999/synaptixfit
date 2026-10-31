import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';

/// Pasos numerados de un ejercicio. Lo usan la ficha del ejercicio y la hoja
/// «Cómo se hace» de la sesión en vivo.
class ExerciseInstructions extends StatelessWidget {
  const ExerciseInstructions({super.key, required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensSpacing.s),
            // Número y texto se leen juntos: una sola parada por paso.
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crece con el texto para que el número quepa al 200 %.
                  CircleAvatar(
                    radius: context.scaled(TokensSize.iconM) / 2,
                    backgroundColor: context.colors.secondaryContainer,
                    child: Text(
                      '${i + 1}',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: TokensSpacing.s),
                  Expanded(
                    child: Text(steps[i], style: context.textStyles.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
