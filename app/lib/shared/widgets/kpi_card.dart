import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/design_system/sv_colors.dart';
import '../../core/design_system/sv_shadows.dart';
import '../../core/design_system/sv_shapes.dart';

class KpiCard extends StatefulWidget {
  const KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.progress,
    this.gradientColors,
    this.accentColor,
    super.key,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final double? progress;
  final List<Color>? gradientColors;
  final Color? accentColor;

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: widget.progress ?? 0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    if (widget.progress != null) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _animCtrl.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant KpiCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress && widget.progress != null) {
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: widget.progress!,
      ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
      _animCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;
    final gradientStart =
        widget.gradientColors?.first ?? accent.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        borderRadius: SVShapes.large16,
        boxShadow: SVShadows.ambientCard,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            gradientStart,
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          if (widget.progress != null)
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, _) => SizedBox(
                width: 56,
                height: 56,
                child: CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: _progressAnim.value.clamp(0.0, 1.0),
                    color: accent,
                    trackColor: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.25),
                  ),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.12),
                      ),
                      child: Icon(widget.icon, size: 18, color: accent),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, size: 22, color: accent),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.value,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.1,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: SVColors.onSurfaceMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 4) / 2;
    const strokeWidth = 4.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
