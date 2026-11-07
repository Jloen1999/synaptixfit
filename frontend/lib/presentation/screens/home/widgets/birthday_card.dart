import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Tarjeta de Inicio el día del cumpleaños (ADR 0036): «¡Feliz cumpleaños,
/// Ana!». Solo felicita; no pide nada ni distrae del resto del día.
class BirthdayCard extends StatelessWidget {
  const BirthdayCard({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final onColor = context.colors.onTertiaryContainer;
    return Semantics(
      container: true,
      child: AppCard(
        color: context.colors.tertiaryContainer,
        child: Row(
          children: [
            Icon(Icons.cake_rounded, color: onColor, size: TokensSize.iconL),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty
                        ? l10n.homeBirthdayTitleNoName
                        : l10n.homeBirthdayTitle(name),
                    style: context.textStyles.titleMedium?.copyWith(
                      color: onColor,
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.xxs),
                  Text(
                    l10n.homeBirthdayMessage,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: onColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
