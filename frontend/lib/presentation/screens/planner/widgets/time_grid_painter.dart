import 'package:flutter/material.dart';

import 'week_grid_geometry.dart';

/// Fondo del lienzo: líneas de hora y media hora, separadores de día, zona
/// pasada sombreada, columna de hoy resaltada y línea de «ahora».
class TimeGridPainter extends CustomPainter {
  TimeGridPainter({
    required this.geometry,
    required this.weekStart,
    required this.now,
    required this.lineColor,
    required this.halfLineColor,
    required this.pastColor,
    required this.todayColor,
    required this.nowColor,
  });

  final WeekGridGeometry geometry;
  final DateTime weekStart;
  final DateTime now;
  final Color lineColor;
  final Color halfLineColor;
  final Color pastColor;
  final Color todayColor;
  final Color nowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final todayIndex = g.dayIndexOf(now, weekStart);
    final nowMinutes = WeekGridGeometry.minutesOfDay(now);
    final weekEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 7,
    );

    // Zona pasada.
    final past = Paint()..color = pastColor;
    if (!now.isBefore(weekEnd)) {
      canvas.drawRect(Offset.zero & size, past);
    } else if (todayIndex != null) {
      if (todayIndex > 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, g.dayLeft(todayIndex), size.height),
          past,
        );
      }
      final y = g.minutesToY(nowMinutes).clamp(0.0, size.height);
      canvas.drawRect(
        Rect.fromLTWH(g.dayLeft(todayIndex), 0, g.dayWidth, y),
        past,
      );
    }

    // Columna de hoy.
    if (todayIndex != null) {
      canvas.drawRect(
        Rect.fromLTWH(g.dayLeft(todayIndex), 0, g.dayWidth, size.height),
        Paint()..color = todayColor,
      );
    }

    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final half = Paint()
      ..color = halfLineColor
      ..strokeWidth = 1;
    for (var h = g.startHour; h <= g.endHour; h++) {
      final y = g.minutesToY(h * 60);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      if (h < g.endHour) {
        final yHalf = g.minutesToY(h * 60 + 30);
        canvas.drawLine(Offset(0, yHalf), Offset(size.width, yHalf), half);
      }
    }
    for (var d = 0; d <= 7; d++) {
      final x = g.dayLeft(d);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }

    // Línea de «ahora».
    if (todayIndex != null &&
        nowMinutes >= g.startMinutes &&
        nowMinutes <= g.endMinutes) {
      final y = g.minutesToY(nowMinutes);
      final paint = Paint()
        ..color = nowColor
        ..strokeWidth = 2;
      final left = g.dayLeft(todayIndex);
      canvas
        ..drawLine(Offset(left, y), Offset(left + g.dayWidth, y), paint)
        ..drawCircle(Offset(left, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(TimeGridPainter old) =>
      old.geometry.dayWidth != geometry.dayWidth ||
      old.geometry.hourHeight != geometry.hourHeight ||
      old.weekStart != weekStart ||
      old.now.minute != now.minute ||
      old.now.hour != now.hour ||
      old.lineColor != lineColor ||
      old.pastColor != pastColor ||
      old.todayColor != todayColor;
}
