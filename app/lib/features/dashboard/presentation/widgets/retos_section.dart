import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../application/dashboard_provider.dart';
import 'reto_activo_card.dart';

/// Sección de retos activos con header y lista de tarjetas.
class RetosSection extends StatelessWidget {
  const RetosSection({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Retos activos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            if (data.retosActivos.isNotEmpty)
              Text(
                '${data.retosActivos.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: SVColors.onSurfaceMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.retosActivos.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    color: SVColors.onSurfaceMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'No tienes retos activos. ¡Crea uno!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: SVColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...data.retosActivos.map(
            (reto) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RetoActivoCard(
                reto: reto,
                progreso: data.progresoReto(reto.id),
                tieneTareas: data.tieneHitosReto(reto.id),
                onTap: () => context.push('/retos/${reto.id}'),
              ),
            ),
          ),
      ],
    );
  }
}
