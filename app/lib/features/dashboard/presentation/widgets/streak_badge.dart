import 'package:flutter/material.dart';

/// Badges de racha de entrenamiento y estudio.
class StreakRow extends StatelessWidget {
  const StreakRow({
    required this.rachaEntrenamiento,
    required this.diasEstudio,
    super.key,
  });

  final int rachaEntrenamiento;
  final int diasEstudio;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StreakChip(
          icon: '🔥',
          label: '$rachaEntrenamiento días',
          color: const Color(0xFFE8A838),
        ),
        const SizedBox(width: 8),
        _StreakChip(
          icon: '🧠',
          label: '$diasEstudio/7 días',
          color: const Color(0xFF2196F3),
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$icon $label',
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
