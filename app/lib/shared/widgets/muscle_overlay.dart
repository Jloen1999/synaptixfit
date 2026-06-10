import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/sv_colors.dart';

class MuscleOverlay extends StatefulWidget {
  const MuscleOverlay({
    required this.musculo,
    this.urlImagen,
    this.alignment = Alignment.centerLeft,
    this.index = 0,
    super.key,
  });

  final String musculo;
  final String? urlImagen;
  final Alignment alignment;
  final int index;

  @override
  State<MuscleOverlay> createState() => _MuscleOverlayState();
}

class _MuscleOverlayState extends State<MuscleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _float;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _float = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _floatCtrl,
        curve: const Interval(0, 0.15, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showImage = widget.urlImagen != null && widget.urlImagen!.isNotEmpty;
    final isLeft = widget.alignment == Alignment.centerLeft;

    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeIn.value,
          child: Transform.translate(
            offset: Offset(0, _float.value),
            child: child,
          ),
        );
      },
      child: Container(
        width: 72,
        margin: EdgeInsets.only(
          left: isLeft ? 8 : 0,
          right: isLeft ? 0 : 8,
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showImage)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.urlImagen!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 36,
                    height: 36,
                    color: SVColors.surfaceContainerHighest,
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      size: 16,
                      color: Colors.white24,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 36,
                    height: 36,
                    color: SVColors.surfaceContainerHighest,
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      size: 16,
                      color: Colors.white24,
                    ),
                  ),
                ),
              )
            else
              const Icon(
                Icons.fitness_center_rounded,
                size: 20,
                color: Colors.white38,
              ),
            const SizedBox(height: 3),
            Text(
              widget.musculo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.2,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
