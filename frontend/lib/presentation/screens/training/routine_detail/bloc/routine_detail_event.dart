part of 'routine_detail_bloc.dart';

@freezed
sealed class RoutineDetailEvent with _$RoutineDetailEvent {
  const factory RoutineDetailEvent.started(String routineId) =
      RoutineDetailStarted;

  const factory RoutineDetailEvent.refreshed() = RoutineDetailRefreshed;

  // ---------------------------------------------------------- semanas y días
  const factory RoutineDetailEvent.weekAdded() = RoutineDetailWeekAdded;

  const factory RoutineDetailEvent.weekRenamed(String weekId, String name) =
      RoutineDetailWeekRenamed;

  const factory RoutineDetailEvent.weekDeleted(String weekId) =
      RoutineDetailWeekDeleted;

  const factory RoutineDetailEvent.dayAdded(String weekId, int dayNumber) =
      RoutineDetailDayAdded;

  const factory RoutineDetailEvent.dayRenamed(String dayId, String name) =
      RoutineDetailDayRenamed;

  const factory RoutineDetailEvent.dayDeleted(String dayId) =
      RoutineDetailDayDeleted;

  // ---------------------------------------------------------- ejercicios
  const factory RoutineDetailEvent.exerciseAdded(
    String dayId,
    Exercise exercise,
  ) = RoutineDetailExerciseAdded;

  const factory RoutineDetailEvent.exerciseRemoved(String plannedExerciseId) =
      RoutineDetailExerciseRemoved;

  const factory RoutineDetailEvent.exerciseMoved(
    String dayId,
    String plannedExerciseId, {
    required bool up,
  }) = RoutineDetailExerciseMoved;

  /// Edición en línea de series, repeticiones, peso o descanso: se ve al
  /// instante y se guarda detrás, sin bloquear los demás campos.
  const factory RoutineDetailEvent.exerciseUpdated(
    String plannedExerciseId,
    ExerciseParameters parameters,
  ) = RoutineDetailExerciseUpdated;

  /// Sustituye el ejercicio de un hueco por [exerciseId] (misma posición).
  const factory RoutineDetailEvent.exerciseReplaced(
    String plannedExerciseId,
    String exerciseId,
  ) = RoutineDetailExerciseReplaced;

  // ---------------------------------------------------------- rutina
  const factory RoutineDetailEvent.statusChanged(RoutineStatus status) =
      RoutineDetailStatusChanged;

  /// Edita los datos generales; los nulos no cambian.
  const factory RoutineDetailEvent.detailsUpdated({
    String? name,
    String? description,
    Visibility? visibility,
    TrainingGoal? goal,
  }) = RoutineDetailDetailsUpdated;

  const factory RoutineDetailEvent.duplicated({String? name}) =
      RoutineDetailDuplicated;

  const factory RoutineDetailEvent.deleted() = RoutineDetailDeleted;

  /// Clona una rutina ajena (de la comunidad).
  const factory RoutineDetailEvent.cloned() = RoutineDetailCloned;

  /// Empieza una sesión de un día de la rutina.
  const factory RoutineDetailEvent.sessionStarted(String dayId) =
      RoutineDetailSessionStarted;

  /// Salta un día (deja de proponerse y sale del calendario).
  const factory RoutineDetailEvent.daySkipped(String dayId) =
      RoutineDetailDaySkipped;

  /// Recupera un día saltado.
  const factory RoutineDetailEvent.dayUnskipped(String dayId) =
      RoutineDetailDayUnskipped;

  /// Pasa a ser la rutina en curso (el servidor pausa la anterior).
  const factory RoutineDetailEvent.activated() = RoutineDetailActivated;

  /// Repite el ciclo: avance a cero, desde hoy y en curso.
  const factory RoutineDetailEvent.restarted() = RoutineDetailRestarted;
}
