import '../enums/training_enums.dart';
import '../enums/visibility.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/training/routine.dart';
import '../models/training/routine_draft.dart';
import '../models/training/training_page.dart';
import '../models/training/routine_template.dart';

/// Rutinas de entrenamiento (`/api/v1/routines`). Las operaciones de edición
/// devuelven la rutina completa ya actualizada.
abstract interface class RoutineRepositoryContract {
  Future<AppResult<TrainingPage<RoutineSummary>>> getMyRoutines({
    RoutineStatus? status,
    int page = 0,
    int size = 20,
  });

  Future<AppResult<TrainingPage<RoutineSummary>>> getCommunityRoutines({
    String? query,
    TrainingGoal? goal,
    int page = 0,
    int size = 20,
  });

  Future<AppResult<Routine>> getRoutine(String routineId);

  Future<AppResult<Routine>> createRoutine(RoutineDraft draft);

  /// Los parámetros nulos no cambian; [clearStartDate] borra la fecha de inicio.
  Future<AppResult<Routine>> updateRoutine(
    String routineId, {
    String? name,
    String? description,
    Visibility? visibility,
    TrainingGoal? goal,
    DateTime? startDate,
    bool clearStartDate = false,
  });

  Future<AppResult<Routine>> changeStatus(
    String routineId,
    RoutineStatus status,
  );

  Future<AppResult<Unit>> deleteRoutine(String routineId);

  /// Salta un día (deja de proponerse y sale del calendario).
  Future<AppResult<Routine>> skipDay(String routineId, String dayId);

  /// Recupera un día saltado.
  Future<AppResult<Routine>> unskipDay(String routineId, String dayId);

  /// Nuevo ciclo: avance a cero, desde hoy y en curso.
  Future<AppResult<Routine>> restartRoutine(String routineId);

  Future<AppResult<Routine>> duplicateRoutine(String routineId, {String? name});

  Future<AppResult<Routine>> cloneRoutine(String routineId);

  Future<AppResult<Routine>> addWeek(
    String routineId, {
    String? name,
    WeekType? type,
  });

  Future<AppResult<Routine>> updateWeek(
    String routineId,
    String weekId, {
    String? name,
    WeekType? type,
  });

  Future<AppResult<Routine>> deleteWeek(String routineId, String weekId);

  Future<AppResult<Routine>> addDay(
    String routineId,
    String weekId, {
    required int dayNumber,
    String? name,
  });

  Future<AppResult<Routine>> renameDay(
    String routineId,
    String dayId,
    String name,
  );

  Future<AppResult<Routine>> deleteDay(String routineId, String dayId);

  Future<AppResult<Routine>> addExercise(
    String routineId,
    String dayId, {
    required String exerciseId,
    required ExerciseParameters parameters,
  });

  Future<AppResult<Routine>> reorderExercises(
    String routineId,
    String dayId,
    List<String> plannedExerciseIds,
  );

  Future<AppResult<Routine>> updateExercise(
    String routineId,
    String plannedExerciseId,
    ExerciseParameters parameters,
  );

  Future<AppResult<Routine>> removeExercise(
    String routineId,
    String plannedExerciseId,
  );

  /// Sustituye el ejercicio de un hueco por [exerciseId] (misma posición).
  Future<AppResult<Routine>> replaceExercise(
    String routineId,
    String plannedExerciseId,
    String exerciseId,
  );

  /// Genera una propuesta con el motor de reglas (y la IA si [useAi]).
  Future<AppResult<RoutineProposal>> generateRoutine({
    required int durationWeeks,
    TrainingGoal? goal,
    bool useAi = true,
  });

  /// Pide a la IA que refine una propuesta (o una rutina en edición).
  Future<AppResult<RoutineProposal>> refineRoutine(RoutineProposal proposal);

  /// Plantillas listas para usar (ADR 0032).
  Future<AppResult<List<RoutineTemplate>>> listTemplates();

  /// Crea una rutina propia y privada a partir de una plantilla.
  Future<AppResult<Routine>> useTemplate(String templateId);
}
