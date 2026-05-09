import 'package:flutter/material.dart';
import '../../core/design_system/sv_colors.dart';
import '../../core/design_system/sv_shapes.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({this.height = 80, super.key});

  final double height;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final opacity = 0.3 + 0.3 * (_ctrl.value * 2 < 1
            ? _ctrl.value * 2
            : 2 - _ctrl.value * 2);
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: SVShapes.standard12,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                SVColors.surfaceContainerHighest.withValues(alpha: opacity),
                SVColors.surfaceContainerHighest.withValues(alpha: 1.0),
                SVColors.surfaceContainerHighest.withValues(alpha: opacity),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
