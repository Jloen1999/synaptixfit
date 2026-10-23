import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/domain/models/training/exercise.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/models/training/session.dart';

/// Datos de prueba compartidos por los tests del módulo training.
abstract final class TrainingFixtures {
  static const account = Account(
    id: 'u1',
    email: 'a@b.co',
    fullName: 'Ana',
    level: 3,
    levelXp: 40,
    levelThreshold: 300,
    streak: 2,
    privacy: Visibility.private,
    role: UserRole.user,
    hasPassword: true,
    googleLinked: false,
  );

  static const squat = Exercise(
    id: 'ex-squat',
    name: 'Sentadilla',
    difficulty: ExerciseDifficulty.beginner,
    modality: Modality.strength,
    met: 5,
    previewUrl: 'https://cdn/squat.png',
  );

  static const run = Exercise(
    id: 'ex-run',
    name: 'Carrera',
    difficulty: ExerciseDifficulty.beginner,
    modality: Modality.aerobic,
    met: 8,
  );

  static PlannedExercise planned(String id, {int order = 0, int rest = 90}) =>
      PlannedExercise(
        id: id,
        exerciseId: 'ex-$id',
        exerciseName: 'Ejercicio $id',
        modality: Modality.strength,
        met: 5,
        order: order,
        parameters: ExerciseParameters(sets: 3, reps: 10, restSeconds: rest),
      );

  static Routine routine({bool owned = true}) => Routine(
    id: 'r1',
    ownerId: 'u1',
    owned: owned,
    name: 'Fuerza',
    visibility: Visibility.private,
    status: RoutineStatus.active,
    durationWeeks: 1,
    exerciseCount: 2,
    totalDays: 1,
    completedDays: 0,
    weeks: [
      RoutineWeek(
        id: 'w1',
        number: 1,
        status: ProgressStatus.pending,
        days: [
          RoutineDay(
            id: 'd1',
            dayNumber: 1,
            status: ProgressStatus.pending,
            exercises: [planned('p1'), planned('p2', order: 1, rest: 60)],
          ),
        ],
      ),
    ],
  );

  static TrainingSession session({
    SessionStatus status = SessionStatus.inProgress,
    List<SessionSet> sets = const [],
    DateTime? startedAt,
  }) => TrainingSession(
    id: 's1',
    routineId: 'r1',
    dayId: 'd1',
    type: SessionType.routine,
    status: status,
    startedAt: startedAt ?? DateTime(2026, 10, 18, 10),
    sets: sets,
  );
}
