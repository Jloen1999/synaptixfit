import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Pastilla de estado o dato: texto (y un icono opcional) de un color sobre ese
/// mismo color al 12 %. Es la única pastilla de la app; los módulos solo
/// deciden la etiqueta, el icono y el color. Los colores válidos como texto
/// están en la lista «pastillas tintadas» de `contrast_test.dart`.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.semanticLabel,
  });

  final String label;

  /// Color del texto y del tinte; por defecto `onSurfaceVariant` (neutro).
  final Color? color;
  final IconData? icon;

  /// Sustituye a [label] para el lector de pantalla (p. ej. «12:30» → «12
  /// minutos y 30 segundos»).
  final String? semanticLabel;

  /// Opacidad del tinte de fondo; el test de contraste la valida.
  static const tintAlpha = 0.12;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.onSurfaceVariant;
    final icon = this.icon;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensSpacing.s,
          vertical: TokensSpacing.xxs,
        ),
        decoration: BoxDecoration(
          // Tinte opaco sobre `surface`: el contraste es el mismo que valida
          // el test esté la pastilla sobre una tarjeta o sobre el fondo.
          color: Color.alphaBlend(
            color.withValues(alpha: tintAlpha),
            context.colors.surface,
          ),
          borderRadius: BorderRadius.circular(TokensRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: TokensSize.iconXs, color: color),
              const SizedBox(width: TokensSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
