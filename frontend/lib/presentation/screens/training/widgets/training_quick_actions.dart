import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Un atajo de Entreno: icono, texto corto y qué hace al tocarlo.
class TrainingQuickAction {
  const TrainingQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.key,
  });

  final IconData icon;
  final String label;

  /// Nulo mientras la acción no se puede usar (p. ej. empezando una sesión).
  final VoidCallback? onTap;

  /// Para que la guía de la primera vez pueda señalar este atajo (ADR 0049).
  final Key? key;
}

/// Fila de atajos de Gimnasio y de Correr (ADR 0055): lo que más se usa, a un
/// toque y sin bajar. Van juntos en una tarjeta: sobre su superficie se leen
/// igual en claro y en oscuro. Con letra grande o pantalla estrecha no se
/// deslizan fuera de la vista: pasan a varias filas ([AppTileGrid]).
class TrainingQuickActions extends StatelessWidget {
  const TrainingQuickActions({super.key, required this.actions});

  final List<TrainingQuickAction> actions;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(TokensSpacing.xs),
    child: AppTileGrid(
      minTileWidth: TokensSize.quickActionMinWidth,
      spacing: TokensSpacing.xxs,
      children: [
        for (final action in actions)
          _QuickActionButton(key: action.key, action: action),
      ],
    ),
  );
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({super.key, required this.action});

  final TrainingQuickAction action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // La acción va también en el nodo del lector: con `excludeSemantics`, el
    // toque del InkWell no le llegaría (TalkBack y VoiceOver).
    return Semantics(
      container: true,
      button: true,
      enabled: action.onTap != null,
      label: action.label,
      onTap: action.onTap,
      excludeSemantics: true,
      child: AppFocusOutline(
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(TokensRadius.m),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensSpacing.xxs,
              vertical: TokensSpacing.s,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: TokensLayout.minTouchTarget,
                  height: TokensLayout.minTouchTarget,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      colors.primary.withValues(alpha: AppPill.tintAlpha),
                      colors.surface,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action.icon, color: colors.primary),
                ),
                const SizedBox(height: TokensSpacing.xs),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  // 14 px: más pequeño, el círculo de color pesa más que el
                  // texto y la comprobación de contraste lo toma por fondo.
                  style: context.textStyles.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
