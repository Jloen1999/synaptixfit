import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/pomodoro_session.dart';

/// CustomPainter que dibuja un anillo circular de progreso con color segun la
/// fase activa del Pomodoro. Soporta repaint via [animation].
class PomodoroProgressPainter extends CustomPainter {
  const PomodoroProgressPainter({
    required this.progress,
    required this.phase,
    this.animation,
  }) : super(repaint: animation);

  /// Valor de 0.0 a 1.0.
  final double progress;

  /// Fase activa que determina el color del arco.
  final PomodoroPhase phase;

  /// Listenable opcional para animar repaints (ej. AnimationController).
  final Listenable? animation;

  Color get _arcColor {
    switch (phase) {
      case PomodoroPhase.work:
        return const Color(0xFFE53935); // rojo
      case PomodoroPhase.shortBreak:
        return const Color(0xFF43A047); // verde
      case PomodoroPhase.longBreak:
        return const Color(0xFF1E88E5); // azul
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6.0;
    const strokeWidth = 12.0;

    // Fondo gris claro
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Arco de progreso
    final progressPaint = Paint()
      ..color = _arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // empieza desde arriba
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PomodoroProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.animation != animation;
  }
}
