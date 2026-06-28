import 'package:flutter/material.dart';

import '../../infrastructure/grid_math.dart';

class TimeGridPainter extends CustomPainter {
  const TimeGridPainter({this.hourGutter = 0});

  /// Ancho de la columna izquierda reservada para las etiquetas de hora.
  final double hourGutter;

  @override
  void paint(Canvas canvas, Size size) {
    final gridLeft = hourGutter;
    final gridWidth = size.width - hourGutter;
    final columnWidth = gridWidth / 7;

    final halfHourPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;

    final hourPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    final darkPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5;

    for (var h = 0; h <= GridConstants.hourEnd - GridConstants.hourStart; h++) {
      final y = h * GridConstants.pixelsPerHour;
      final paint = h % 3 == 0 ? darkPaint : hourPaint;
      canvas.drawLine(Offset(gridLeft, y), Offset(size.width, y), paint);
    }

    for (var h = 0; h < GridConstants.hourEnd - GridConstants.hourStart; h++) {
      final y = (h + 0.5) * GridConstants.pixelsPerHour;
      canvas.drawLine(
          Offset(gridLeft, y), Offset(size.width, y), halfHourPaint);
    }

    for (var d = 0; d <= 7; d++) {
      final x = gridLeft + d * columnWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        d == 0 || d == 7 ? darkPaint : hourPaint,
      );
    }

    for (var h = 0; h <= GridConstants.hourEnd - GridConstants.hourStart; h++) {
      final y = h * GridConstants.pixelsPerHour;
      final hourLabel =
          '${(GridConstants.hourStart + h).toString().padLeft(2, '0')}:00';
      final textPainter = TextPainter(
        text: TextSpan(
          text: hourLabel,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - textPainter.height / 2));
    }

    for (var h = 0; h < GridConstants.hourEnd - GridConstants.hourStart; h++) {
      final y = (h + 0.5) * GridConstants.pixelsPerHour;
      final halfLabel =
          '${(GridConstants.hourStart + h).toString().padLeft(2, '0')}:30';
      final textPainter = TextPainter(
        text: TextSpan(
          text: halfLabel,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant TimeGridPainter oldDelegate) =>
      oldDelegate.hourGutter != hourGutter;
}
