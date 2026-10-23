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

  const factory RoutineDetailEvent.exerciseUpdated(
    String plannedExerciseId,
    ExerciseParameters parameters,
  ) = RoutineDetailExerciseUpdated;

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
}
