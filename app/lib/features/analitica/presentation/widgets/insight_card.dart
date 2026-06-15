import 'package:flutter/material.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../domain/insight_correlacion_dto.dart';

// ---------------------------------------------------------------------------
// Tarjeta que muestra un insight de analitica con icono, titulo,
// descripcion y recomendacion accionable.
// ---------------------------------------------------------------------------

class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.insight,
    this.icon = Icons.insights_rounded,
    super.key,
  });

  final InsightCorrelacion insight;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Seleccion del color del icono segun la correlacion
    final abs = insight.coeficiente.abs();
    final bool positiva = insight.coeficiente >= 0;
    final Color iconColor;
    final Color iconBg;
    if (abs < 0.2) {
      iconColor = SVColors.onSurfaceMuted;
      iconBg = SVColors.surfaceContainerHighest;
    } else if (abs >= 0.6) {
      iconColor = positiva ? SVColors.secondary : SVColors.error;
      iconBg = positiva
          ? SVColors.secondary.withValues(alpha: 0.1)
          : SVColors.error.withValues(alpha: 0.1);
    } else {
      iconColor = positiva
          ? SVColors.secondary.withValues(alpha: 0.7)
          : SVColors.error.withValues(alpha: 0.7);
      iconBg = SVColors.accentContainer.withValues(alpha: 0.4);
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: SVShapes.large16,
        side: BorderSide(
          color: SVColors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con icono y titulo
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: SVShapes.standard12,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.titulo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SVColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Correlacion ${insight.direccion} (${(insight.coeficiente * 100).toStringAsFixed(0)}%)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: SVColors.onSurfaceMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Descripcion / interpretacion
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SVColors.surfaceContainerLowest,
                borderRadius: SVShapes.standard12,
                border: Border.all(
                  color: SVColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                insight.interpretacion,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: SVColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Recomendacion
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: SVColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight.recomendacion,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: SVColors.onSurface,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
