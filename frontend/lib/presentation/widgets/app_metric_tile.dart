import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_card.dart';

/// Métrica compacta: icono de color, valor, etiqueta y desglose opcional. Se
/// anuncia como una sola frase («0 kcal totales…») al lector de pantalla.
/// [bare] quita la tarjeta para usarla dentro de otra (sin tarjeta en tarjeta).
class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.detail,
    this.onTap,
    this.bare = false,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  /// Línea secundaria opcional (desglose de la cifra).
  final String? detail;
  final VoidCallback? onTap;

  /// Sin borde de tarjeta: un relleno suave dentro de otra superficie. No
  /// admite [onTap].
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.onSurfaceVariant;
    final detail = this.detail;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(TokensSpacing.s),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(TokensRadius.m),
          ),
          child: ExcludeSemantics(
            child: Icon(icon, color: color, size: TokensSize.iconS),
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        Text(value, style: context.textStyles.headlineSmall),
        Text(
          label,
          style: context.textStyles.labelMedium?.copyWith(color: muted),
        ),
        if (detail != null) ...[
          const SizedBox(height: TokensSpacing.xxs),
          Text(
            detail,
            style: context.textStyles.bodySmall?.copyWith(color: muted),
          ),
        ],
      ],
    );
    // MergeSemantics por fuera para que el toque y el texto sean un solo nodo.
    return MergeSemantics(
      child: bare
          ? Container(
              padding: const EdgeInsets.all(TokensSpacing.m),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(TokensRadius.m),
              ),
              child: content,
            )
          : AppCard(onTap: onTap, child: content),
    );
  }
}
