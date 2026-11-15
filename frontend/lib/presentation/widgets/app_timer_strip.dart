import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_card_tap_area.dart';
import 'app_pill.dart';

/// Franja fina con un temporizador en marcha sobre la navegación (Pomodoro,
/// sala «Estudiar juntos»): icono, qué es y la cuenta atrás. Tocarla abre su
/// pantalla ([AppCardTapArea]: un solo nodo de botón con [semanticLabel] y su
/// toque); [trailing] (p. ej. pausar) va aparte, como hermano, porque un botón
/// no se anida dentro de otro.
class AppTimerStrip extends StatelessWidget {
  const AppTimerStrip({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.clock,
    required this.semanticLabel,
    required this.onTap,
    this.trailing,
  });

  /// Color de la fase: tiñe el fondo y el icono.
  final Color color;
  final IconData icon;
  final String label;

  /// Cuenta atrás («12:34»); vacía si no se sabe todavía.
  final String clock;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.alphaBlend(
        color.withValues(alpha: AppPill.tintAlpha),
        context.colors.surfaceContainer,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppCardTapArea(
              semanticLabel: semanticLabel,
              borderRadius: BorderRadius.zero,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: TokensSpacing.m,
              ),
              onTap: onTap,
              child: Row(
                children: [
                  Icon(icon, color: color, size: TokensSize.iconS),
                  const SizedBox(width: TokensSpacing.s),
                  Flexible(
                    child: Text(
                      label,
                      // Con el texto grande, dos líneas antes que cortar la
                      // fase («Concentración · ronda 1 de 2»).
                      maxLines: context.largeText ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelLarge,
                    ),
                  ),
                  if (clock.isNotEmpty) ...[
                    const SizedBox(width: TokensSpacing.s),
                    Text(
                      clock,
                      style: context.textStyles.titleSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
