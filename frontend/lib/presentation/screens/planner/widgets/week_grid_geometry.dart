import 'dart:math' as math;

/// Intervalo horario con fin exclusivo.
typedef TimeRange = ({DateTime start, DateTime end});

/// Carril asignado a un bloque cuando se solapa con otros en el mismo día.
typedef LaneSlot = ({int lane, int lanes});

/// Matemática pura del lienzo semanal (hora ↔ píxel, día ↔ columna, ajuste a la
/// media hora). No depende de Flutter para poder probarla con tests unitarios.
///
/// El eje vertical empieza en [startHour] (y = 0) y termina en [endHour]; cada
/// columna mide [dayWidth] y la semana empieza el lunes ([weekStart]).
class WeekGridGeometry {
  const WeekGridGeometry({
    required this.dayWidth,
    this.hourHeight = 64,
    this.startHour = 6,
    this.endHour = 23,
    this.snapMinutes = 30,
    this.minDurationMinutes = 30,
  }) : assert(endHour > startHour),
       assert(snapMinutes > 0);

  final double dayWidth;
  final double hourHeight;
  final int startHour;
  final int endHour;
  final int snapMinutes;
  final int minDurationMinutes;

  int get startMinutes => startHour * 60;

  int get endMinutes => endHour * 60;

  double get gridHeight => (endHour - startHour) * hourHeight;

  double get gridWidth => 7 * dayWidth;

  double get pixelsPerMinute => hourHeight / 60;

  // --------------------------------------------------------------- vertical

  /// Minutos desde medianoche → y (sin recortar).
  double minutesToY(int minutesOfDay) =>
      (minutesOfDay - startMinutes) * pixelsPerMinute;

  /// y → minutos desde medianoche (sin ajustar).
  double yToMinutes(double y) => startMinutes + y / pixelsPerMinute;

  /// Redondea a la fracción de [snapMinutes] más cercana.
  int snap(num minutes) => (minutes / snapMinutes).round() * snapMinutes;

  /// y → minutos ajustados y limitados a la franja visible.
  int yToSnappedMinutes(double y) =>
      snap(yToMinutes(y)).clamp(startMinutes, endMinutes);

  /// y de una celda tocada → minuto de inicio de su franja (hacia abajo).
  int yToSlotStartMinutes(double y) {
    final raw = yToMinutes(y).floor();
    final slot = (raw ~/ snapMinutes) * snapMinutes;
    return slot.clamp(startMinutes, endMinutes - snapMinutes);
  }

  static int minutesOfDay(DateTime t) => t.hour * 60 + t.minute;

  /// Parte visible de [range] dentro del día de [range.start], en minutos.
  ({int from, int to})? visibleMinutes(TimeRange range) {
    final from = minutesOfDay(range.start);
    final sameDay =
        range.end.year == range.start.year &&
        range.end.month == range.start.month &&
        range.end.day == range.start.day;
    final to = sameDay ? minutesOfDay(range.end) : 24 * 60;
    final clippedFrom = math.max(from, startMinutes);
    final clippedTo = math.min(to, endMinutes);
    if (clippedTo <= clippedFrom) return null;
    return (from: clippedFrom, to: clippedTo);
  }

  /// Posición vertical y altura de un bloque (`null` si cae fuera de la franja).
  ({double top, double height})? verticalExtent(TimeRange range) {
    final visible = visibleMinutes(range);
    if (visible == null) return null;
    return (
      top: minutesToY(visible.from),
      height: (visible.to - visible.from) * pixelsPerMinute,
    );
  }

  // ------------------------------------------------------------- horizontal

  /// Índice del día (0 = lunes … 6 = domingo) o `null` si no es de esta semana.
  int? dayIndexOf(DateTime date, DateTime weekStart) {
    final day = DateTime(date.year, date.month, date.day);
    final monday = DateTime(weekStart.year, weekStart.month, weekStart.day);
    // Diferencia en días naturales (robusta ante cambios de horario).
    final diff =
        (DateTime.utc(day.year, day.month, day.day)
                    .difference(
                      DateTime.utc(monday.year, monday.month, monday.day),
                    )
                    .inHours /
                24)
            .round();
    return diff >= 0 && diff < 7 ? diff : null;
  }

  double dayLeft(int dayIndex) => dayIndex * dayWidth;

  /// x → índice de día (limitado a 0..6).
  int xToDayIndex(double x) => (x / dayWidth).floor().clamp(0, 6);

  /// Fecha y hora local de un día de la semana y un minuto del día.
  static DateTime dateTimeAt(DateTime weekStart, int dayIndex, int minutes) =>
      DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + dayIndex,
        minutes ~/ 60,
        minutes % 60,
      );

  /// Hora de inicio de la celda tocada en (x, y).
  DateTime slotAt(DateTime weekStart, double x, double y) =>
      dateTimeAt(weekStart, xToDayIndex(x), yToSlotStartMinutes(y));

  // --------------------------------------------------- arrastrar y redimensionar

  /// Nuevo horario al soltar un bloque arrastrado: se desplaza [dx], [dy] desde su
  /// posición original, conservando la duración, ajustado a [snapMinutes] y
  /// dentro de la franja visible y de la semana.
  TimeRange moveBy(
    TimeRange original,
    DateTime weekStart, {
    required double dx,
    required double dy,
  }) {
    final duration = original.end.difference(original.start).inMinutes;
    final originDay = dayIndexOf(original.start, weekStart) ?? 0;
    final centerX = dayLeft(originDay) + dayWidth / 2 + dx;
    final targetDay = xToDayIndex(centerX);
    final rawStart = minutesOfDay(original.start) + dy / pixelsPerMinute;
    final maxStart = math.max(startMinutes, endMinutes - duration);
    final start = snap(rawStart).clamp(startMinutes, maxStart);
    final newStart = dateTimeAt(weekStart, targetDay, start);
    return (start: newStart, end: newStart.add(Duration(minutes: duration)));
  }

  /// Nuevo fin al tirar del borde inferior [dy] píxeles: ajustado, con duración
  /// mínima [minDurationMinutes] y sin pasar de [endHour].
  DateTime resizeEndBy(TimeRange original, {required double dy}) {
    final startMin = minutesOfDay(original.start);
    final duration = original.end.difference(original.start).inMinutes;
    final rawEnd = startMin + duration + dy / pixelsPerMinute;
    final limit = math.max(endMinutes, startMin + duration);
    final end = snap(rawEnd).clamp(startMin + minDurationMinutes, limit);
    return original.start.add(Duration(minutes: end - startMin));
  }

  // ------------------------------------------------------------- solapes

  /// Reparte en carriles los bloques de un mismo día que se solapan, para
  /// pintarlos uno al lado del otro. Devuelve un [LaneSlot] por cada rango, en el
  /// mismo orden de entrada.
  static List<LaneSlot> assignLanes(List<TimeRange> ranges) {
    final order = List<int>.generate(ranges.length, (i) => i)
      ..sort((a, b) {
        final byStart = ranges[a].start.compareTo(ranges[b].start);
        return byStart != 0 ? byStart : ranges[b].end.compareTo(ranges[a].end);
      });
    final lanes = List<int>.filled(ranges.length, 0);
    final counts = List<int>.filled(ranges.length, 1);

    var cluster = <int>[];
    var laneEnds = <DateTime>[];
    DateTime? clusterEnd;

    void closeCluster() {
      for (final i in cluster) {
        counts[i] = laneEnds.length;
      }
      cluster = [];
      laneEnds = [];
      clusterEnd = null;
    }

    for (final i in order) {
      final r = ranges[i];
      if (clusterEnd != null && !r.start.isBefore(clusterEnd!)) closeCluster();
      var lane = laneEnds.indexWhere((end) => !r.start.isBefore(end));
      if (lane == -1) {
        laneEnds.add(r.end);
        lane = laneEnds.length - 1;
      } else {
        laneEnds[lane] = r.end;
      }
      lanes[i] = lane;
      cluster.add(i);
      clusterEnd = clusterEnd == null || r.end.isAfter(clusterEnd!)
          ? r.end
          : clusterEnd;
    }
    closeCluster();
    return [
      for (var i = 0; i < ranges.length; i++)
        (lane: lanes[i], lanes: counts[i]),
    ];
  }
}
