import 'package:flutter/material.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../application/dashboard_provider.dart';

/// Tarjeta de rutina activa.
class RutinaActivaCard extends StatelessWidget {
  const RutinaActivaCard({required this.rutina, this.onTap, super.key});

  final RutinaActivaDashboard rutina;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = rutina.rutina;

    final objetivoIcono = switch (r.objetivo) {
      'fuerza' => Icons.fitness_center_rounded,
      'resistencia' => Icons.timer_rounded,
      'hipertrofia' => Icons.trending_up_rounded,
      'flexibilidad' => Icons.self_improvement_rounded,
      _ => Icons.fitness_center_rounded,
    };

    final objetivoEtiqueta = switch (r.objetivo) {
      'fuerza' => 'Fuerza',
      'resistencia' => 'Resistencia',
      'hipertrofia' => 'Hipertrofia',
      'flexibilidad' => 'Flexibilidad',
      _ => r.objetivo,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF00ACC1).withValues(alpha: 0.15),
        ),
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00ACC1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(objetivoIcono,
                            size: 10, color: const Color(0xFF00ACC1)),
                        const SizedBox(width: 3),
                        Text(
                          objetivoEtiqueta,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF00ACC1),
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: SVColors.onSurfaceMuted.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${rutina.ejerciciosCount} ejercicios',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: SVColors.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: SVColors.onSurfaceMuted.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${r.duracionSemanas} sem',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: SVColors.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: SVColors.onSurfaceMuted,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                r.nombre,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
