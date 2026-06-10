import 'package:flutter/material.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../shared/models/db_models.dart';

/// Tarjeta resumen de bienestar con IMC, peso y objetivo.
class BienestarCard extends StatelessWidget {
  const BienestarCard({required this.perfil, super.key});

  final PerfilBienestarDb perfil;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Resumen de bienestar',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _BienestarChip(
                label: 'IMC ${perfil.imc.toStringAsFixed(1)}',
                sublabel: perfil.imcCategoria,
                icon: Icons.monitor_weight_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              _BienestarChip(
                label: '${perfil.pesoKg.toStringAsFixed(1)} kg',
                sublabel: 'Peso actual',
                icon: Icons.scale_rounded,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 10),
              _BienestarChip(
                label: _objetivoLabel(perfil.objetivoPrincipal),
                sublabel: 'Objetivo',
                icon: Icons.flag_rounded,
                color: SVColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _objetivoLabel(String objetivo) => switch (objetivo) {
        'fitness_general' => 'Fitness',
        'perder_peso' => 'Perder peso',
        'ganar_masa' => 'Masa muscular',
        'fuerza' => 'Fuerza',
        'resistencia' => 'Resistencia',
        'movilidad' => 'Movilidad',
        _ => objetivo,
      };
}

class _BienestarChip extends StatelessWidget {
  const _BienestarChip({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: SVColors.onSurfaceMuted,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
