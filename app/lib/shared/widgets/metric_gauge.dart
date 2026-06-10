import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/sv_colors.dart';

class MetricGauge extends StatefulWidget {
  const MetricGauge({
    required this.value,
    required this.label,
    this.subtitle,
    this.alert,
    this.size = 120,
    super.key,
  });

  final double value;
  final String label;
  final String? subtitle;
  final String? alert;
  final double size;

  @override
  State<MetricGauge> createState() => _MetricGaugeState();
}

class _MetricGaugeState extends State<MetricGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.value.clamp(0, 100) / 100)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(MetricGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value.clamp(0, 100) / 100,
      ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _ringColor(double pct) {
    if (pct < 0.30) return SVColors.error;
    if (pct < 0.50) return const Color(0xFFE8A838);
    if (pct < 0.70) return const Color(0xFFF5A623);
    if (pct < 0.85) return SVColors.secondary;
    return const Color(0xFF00C9A7);
  }

  Color _bgRingColor(ColorScheme cs) {
    return cs.surfaceContainerHighest;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = widget.value.clamp(0, 100) / 100;
    final color = _ringColor(pct);

    return SizedBox(
      width: widget.size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size * 0.75,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _GaugePainter(
                    progress: _animation.value,
                    ringColor: color,
                    bgColor: _bgRingColor(cs),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.value.round()}',
                          style: TextStyle(
                            fontSize: widget.size * 0.28,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            fontFamily: 'DM Sans',
                            letterSpacing: -1,
                            height: 1,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: widget.size * 0.10,
                            fontWeight: FontWeight.w500,
                            color: SVColors.onSurfaceMuted,
                            fontFamily: 'DM Sans',
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.size * 0.11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              fontFamily: 'DM Sans',
              height: 1.2,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.size * 0.09,
                fontWeight: FontWeight.w400,
                color: SVColors.onSurfaceVariant,
                fontFamily: 'DM Sans',
                height: 1.2,
              ),
            ),
          ],
          if (widget.alert != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.alert!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.size * 0.085,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: 'DM Sans',
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.ringColor,
    required this.bgColor,
  });

  final double progress;
  final Color ringColor;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 10.0;
    const startAngle = -math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final progPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      progPaint,
    );

    final endAngle = startAngle + sweepAngle * progress;
    final dotX = center.dx + radius * math.cos(endAngle);
    final dotY = center.dy + radius * math.sin(endAngle);

    final dotPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.bgColor != bgColor;
  }
}
