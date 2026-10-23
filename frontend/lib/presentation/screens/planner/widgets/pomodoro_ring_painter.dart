import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anillo del temporizador: pista completa y arco con la fracción restante.
class PomodoroRingPainter extends CustomPainter {
  PomodoroRingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 14,
  });

  /// Fracción restante entre 0 y 1.
  final double fraction;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    final sweep = 2 * math.pi * fraction.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(PomodoroRingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.trackColor != trackColor;
}
