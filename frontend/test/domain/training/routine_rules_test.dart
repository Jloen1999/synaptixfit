import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/models/training/run.dart';

/// Reglas de la lista de rutinas y de los entrenos de carrera que viven en el
/// dominio (antes, en las páginas).
void main() {
  RoutineSummary routine(String id, RoutineStatus status) => RoutineSummary(
    id: id,
    ownerId: 'u1',
    name: 'Rutina $id',
    visibility: Visibility.private,
    status: status,
    durationWeeks: 4,
    exerciseCount: 5,
    totalDays: 12,
    completedDays: status == RoutineStatus.completed ? 12 : 3,
  );

  group('RoutineSummaries.finishedCycle', () {
    test('ofrece la terminada si no queda nada por hacer', () {
      final list = [
        routine('a', RoutineStatus.archived),
        routine('b', RoutineStatus.completed),
      ];
      expect(list.finishedCycle(hasPendingDay: false)?.id, 'b');
    });

    test('nada si aún queda un día por hacer', () {
      final list = [routine('b', RoutineStatus.completed)];
      expect(list.finishedCycle(hasPendingDay: true), isNull);
    });

    test('nada si hay otra rutina en curso', () {
      final list = [
        routine('a', RoutineStatus.active),
        routine('b', RoutineStatus.completed),
      ];
      expect(list.finishedCycle(hasPendingDay: false), isNull);
    });

    test('nada si ninguna está terminada', () {
      final list = [routine('a', RoutineStatus.paused)];
      expect(list.finishedCycle(hasPendingDay: false), isNull);
    });
  });

  group('PlannedRunsToday.dueToday', () {
    final now = DateTime(2026, 11, 14, 10);
    PlannedRun run(String id, DateTime start) => PlannedRun(
      blockId: id,
      workoutId: 'w$id',
      workoutName: 'Series $id',
      start: start,
      end: start.add(const Duration(minutes: 45)),
    );

    test('el primero de hoy que aún no ha terminado', () {
      final list = [
        run('tarde', DateTime(2026, 11, 14, 18)),
        run('mañana', DateTime(2026, 11, 15, 8)),
        run('ya hecho', DateTime(2026, 11, 14, 7)),
        run('mediodía', DateTime(2026, 11, 14, 13)),
      ];
      expect(list.dueToday(now)?.blockId, 'mediodía');
    });

    test('nada si hoy no hay ninguno', () {
      expect([run('mañana', DateTime(2026, 11, 15, 8))].dueToday(now), isNull);
    });
  });
}
