import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/screens/planner/widgets/week_grid_geometry.dart';

void main() {
  // 6:00-23:00, 60 px por hora (1 px por minuto) y columnas de 100 px.
  const g = WeekGridGeometry(dayWidth: 100, hourHeight: 60);
  final monday = DateTime(2025, 10, 13);

  group('eje vertical', () {
    test('dimensiones de la rejilla', () {
      expect(g.gridHeight, 17 * 60);
      expect(g.gridWidth, 700);
    });

    test('minutos ↔ y con origen en la hora de inicio', () {
      expect(g.minutesToY(6 * 60), 0);
      expect(g.minutesToY(8 * 60 + 30), 150);
      expect(g.yToMinutes(150), 8 * 60 + 30);
    });

    test('ajusta a la media hora más cercana y limita a la franja', () {
      expect(g.snap(8 * 60 + 14), 8 * 60);
      expect(g.snap(8 * 60 + 16), 8 * 60 + 30);
      expect(g.yToSnappedMinutes(-200), 6 * 60);
      expect(g.yToSnappedMinutes(5000), 23 * 60);
    });

    test('la celda tocada empieza en su franja (redondeo hacia abajo)', () {
      expect(g.yToSlotStartMinutes(29), 6 * 60);
      expect(g.yToSlotStartMinutes(31), 6 * 60 + 30);
      // Nunca deja una franja que empiece a las 23:00.
      expect(g.yToSlotStartMinutes(10000), 22 * 60 + 30);
    });

    test('extensión vertical recorta lo que queda fuera de 6-23', () {
      final early = g.verticalExtent((
        start: DateTime(2025, 10, 13, 5),
        end: DateTime(2025, 10, 13, 7),
      ));
      expect(early, (top: 0.0, height: 60.0));

      final night = g.verticalExtent((
        start: DateTime(2025, 10, 13, 23, 30),
        end: DateTime(2025, 10, 14, 1),
      ));
      expect(night, isNull);

      final crossing = g.verticalExtent((
        start: DateTime(2025, 10, 13, 22),
        end: DateTime(2025, 10, 14, 1),
      ));
      expect(crossing, (top: 16 * 60.0, height: 60.0));
    });
  });

  group('eje horizontal', () {
    test('índice de día dentro de la semana', () {
      expect(g.dayIndexOf(DateTime(2025, 10, 13, 23), monday), 0);
      expect(g.dayIndexOf(DateTime(2025, 10, 19, 8), monday), 6);
      expect(g.dayIndexOf(DateTime(2025, 10, 20), monday), isNull);
      expect(g.dayIndexOf(DateTime(2025, 10, 12), monday), isNull);
    });

    test('robusto ante el cambio de horario (26/10/2025 en Europa)', () {
      final dstMonday = DateTime(2025, 10, 20);
      expect(g.dayIndexOf(DateTime(2025, 10, 26, 20), dstMonday), 6);
    });

    test('x → día limitado a 0..6', () {
      expect(g.xToDayIndex(0), 0);
      expect(g.xToDayIndex(250), 2);
      expect(g.xToDayIndex(-10), 0);
      expect(g.xToDayIndex(9999), 6);
    });

    test('toque en (x, y) → fecha y hora de la franja', () {
      expect(g.slotAt(monday, 150, 125), DateTime(2025, 10, 14, 8));
    });
  });

  group('arrastrar', () {
    final original = (
      start: DateTime(2025, 10, 14, 9),
      end: DateTime(2025, 10, 14, 10, 30),
    );

    test('mueve de día y de hora conservando la duración', () {
      final moved = g.moveBy(original, monday, dx: 100, dy: 62);
      expect(moved.start, DateTime(2025, 10, 15, 10));
      expect(moved.end, DateTime(2025, 10, 15, 11, 30));
    });

    test('ajusta a 30 minutos', () {
      final moved = g.moveBy(original, monday, dx: 0, dy: 20);
      expect(moved.start, DateTime(2025, 10, 14, 9, 30));
    });

    test('no se sale de la franja ni de la semana', () {
      final up = g.moveBy(original, monday, dx: -1000, dy: -1000);
      expect(up.start, DateTime(2025, 10, 13, 6));
      final down = g.moveBy(original, monday, dx: 1000, dy: 5000);
      expect(down.start, DateTime(2025, 10, 19, 21, 30));
      expect(down.end, DateTime(2025, 10, 19, 23));
    });
  });

  group('redimensionar', () {
    final original = (
      start: DateTime(2025, 10, 14, 9),
      end: DateTime(2025, 10, 14, 10),
    );

    test('alarga ajustando a 30 minutos', () {
      expect(g.resizeEndBy(original, dy: 40), DateTime(2025, 10, 14, 10, 30));
    });

    test('duración mínima de 30 minutos', () {
      expect(g.resizeEndBy(original, dy: -500), DateTime(2025, 10, 14, 9, 30));
    });

    test('no pasa de la hora de fin', () {
      expect(g.resizeEndBy(original, dy: 5000), DateTime(2025, 10, 14, 23));
    });
  });

  group('carriles de solapes', () {
    DateTime t(int h, [int m = 0]) => DateTime(2025, 10, 14, h, m);

    test('sin solapes: un carril cada uno', () {
      final lanes = WeekGridGeometry.assignLanes([
        (start: t(9), end: t(10)),
        (start: t(10), end: t(11)),
      ]);
      expect(lanes, [(lane: 0, lanes: 1), (lane: 0, lanes: 1)]);
    });

    test('solapados se reparten y comparten el número de carriles', () {
      final lanes = WeekGridGeometry.assignLanes([
        (start: t(9), end: t(11)),
        (start: t(9, 30), end: t(10)),
        (start: t(10), end: t(12)),
        (start: t(13), end: t(14)),
      ]);
      expect(lanes[0], (lane: 0, lanes: 2));
      expect(lanes[1], (lane: 1, lanes: 2));
      // Reutiliza el carril 1 que quedó libre a las 10:00.
      expect(lanes[2], (lane: 1, lanes: 2));
      expect(lanes[3], (lane: 0, lanes: 1));
    });
  });
}
