import 'package:flutter/material.dart';

/// Badges de racha de entrenamiento y estudio.
class StreakRow extends StatelessWidget {
  const StreakRow({
    required this.rachaEntrenamiento,
    required this.diasEstudio,
    this.isLoadingEstudio = false,
    super.key,
  });

  final int rachaEntrenamiento;
  final int diasEstudio;
  final bool isLoadingEstudio;

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
        if (isLoadingEstudio)
          const _LoadingStreakChip(color: Color(0xFF2196F3))
        else
          _StreakChip(
            icon: '🧠',
            label: '$diasEstudio/7 días',
            color: const Color(0xFF2196F3),
          ),
      ],
    );
  }
}

class _LoadingStreakChip extends StatefulWidget {
  const _LoadingStreakChip({required this.color});
  final Color color;

  @override
  State<_LoadingStreakChip> createState() => _LoadingStreakChipState();
}

class _LoadingStreakChipState extends State<_LoadingStreakChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.3 + (_controller.value * 0.4);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.color.withAlpha((20 * opacity).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          width: 64,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: widget.color.withAlpha((40 * opacity).round()),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
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
