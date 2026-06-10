import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Fila de 4 botones de acceso rápido para el dashboard.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionChip(
            icon: Icons.timer_rounded,
            label: 'Pomodoro',
            color: const Color(0xFF2196F3),
            onTap: () {
              // TODO: abrir overlay de Pomodoro
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pomodoro — próximamente')),
              );
            },
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.fitness_center_rounded,
            label: 'Workout',
            color: const Color(0xFF4CAF50),
            onTap: () => context.push('/bienestar/rutina/sesion'),
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.camera_alt_rounded,
            label: 'Escanear',
            color: const Color(0xFFE8A838),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Escanear — próximamente')),
              );
            },
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.add_rounded,
            label: 'Nuevo reto',
            color: const Color(0xFF7C4DFF),
            onTap: () => context.push('/retos/simple'),
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
