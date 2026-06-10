import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../application/dashboard_provider.dart';
import 'rutina_activa_card.dart';

/// Sección de rutinas activas con header y lista de tarjetas.
class RutinasSection extends StatelessWidget {
  const RutinasSection({required this.data, super.key});

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
                color: const Color(0xFF00ACC1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Rutinas activas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            if (data.rutinasActivas.isNotEmpty)
              Text(
                '${data.rutinasActivas.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: SVColors.onSurfaceMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.rutinasActivas.isEmpty)
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
                    Icons.fitness_center_rounded,
                    color: SVColors.onSurfaceMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'No tienes rutinas activas. ¡Crea una!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: SVColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...data.rutinasActivas.map(
            (rutina) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RutinaActivaCard(
                rutina: rutina,
                onTap: () =>
                    context.push('/bienestar/rutina/${rutina.rutina.id}'),
              ),
            ),
          ),
      ],
    );
  }
}
