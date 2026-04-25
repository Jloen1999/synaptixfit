import 'dart:math' as math;
import 'package:flutter/material.dart';

class KpiCard extends StatefulWidget {
  const KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.progress,
    this.gradientColors,
    super.key,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  /// Valor entre 0.0 y 1.0 para mostrar un anillo de progreso animado.
  final double? progress;

  /// Colores opcionales para el gradiente de fondo del card.
  final List<Color>? gradientColors;

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
      duration: const Duration(milliseconds: 900),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: widget.progress ?? 0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    if (widget.progress != null) {
      _animCtrl.forward();
    }
  }

  @override
  void didUpdateWidget(covariant KpiCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress && widget.progress != null) {
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: widget.progress!,
      ).animate(
          CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
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
    final gradientStart = widget.gradientColors?.first ??
        theme.colorScheme.primary.withValues(alpha: 0.08);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.surface, gradientStart],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícono con anillo de progreso opcional
            if (widget.progress != null)
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, _) => SizedBox(
                  width: 52,
                  height: 52,
                  child: CustomPaint(
                    painter: _ProgressRingPainter(
                      progress: _progressAnim.value.clamp(0.0, 1.0),
                      color: theme.colorScheme.primary,
                      trackColor: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.3),
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter para el anillo de progreso circular
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
    final radius = (math.min(size.width, size.height) - 6) / 2;
    const strokeWidth = 3.5;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
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
