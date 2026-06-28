import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bienestar/application/rutina_provider.dart';

/// Fila de 4 botones de acceso rápido para el dashboard.
class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionChip(
            icon: Icons.timer_rounded,
            label: 'Pomodoro',
            color: const Color(0xFF2196F3),
            onTap: () => context.push('/pomodoro'),
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.fitness_center_rounded,
            label: 'Workout',
            color: const Color(0xFF4CAF50),
            onTap: () async {
              final params = await obtenerDiaYRutinaParaQuickAction(ref);
              if (!context.mounted) return;
              if (params == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No tienes una rutina activa para hoy'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                context.push('/bienestar/rutina/sesion', extra: params);
              }
            },
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.camera_alt_rounded,
            label: 'Escanear',
            color: const Color(0xFFE8A838),
            onTap: () => context.push('/escanear'),
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.add_rounded,
            label: 'Nuevo reto',
            color: const Color(0xFF7C4DFF),
            onTap: () => context.push('/retos/crear'),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
