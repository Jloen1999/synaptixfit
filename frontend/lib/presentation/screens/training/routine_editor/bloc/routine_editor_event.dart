part of 'routine_editor_bloc.dart';

@freezed
sealed class RoutineEditorEvent with _$RoutineEditorEvent {
  /// Abre el editor: con IA (paso de parámetros) o manual (rutina vacía).
  const factory RoutineEditorEvent.started({required bool manual}) =
      RoutineEditorStarted;

  // ---------------------------------------------------------- paso 1 (IA)
  const factory RoutineEditorEvent.weeksParamChanged(int weeks) =
      RoutineEditorWeeksParamChanged;

  const factory RoutineEditorEvent.goalParamChanged(TrainingGoal? goal) =
      RoutineEditorGoalParamChanged;

  const factory RoutineEditorEvent.generateRequested() =
      RoutineEditorGenerateRequested;

  const factory RoutineEditorEvent.backToParameters() =
      RoutineEditorBackToParameters;

  // ---------------------------------------------------------- datos generales
  const factory RoutineEditorEvent.nameChanged(String name) =
      RoutineEditorNameChanged;

  const factory RoutineEditorEvent.descriptionChanged(String description) =
      RoutineEditorDescriptionChanged;

  const factory RoutineEditorEvent.goalChanged(TrainingGoal? goal) =
      RoutineEditorGoalChanged;

  const factory RoutineEditorEvent.visibilityChanged(Visibility visibility) =
      RoutineEditorVisibilityChanged;

  // ---------------------------------------------------------- estructura
  /// Añade una semana al final (copiando la anterior si [copyPrevious]).
  const factory RoutineEditorEvent.weekAdded({
    @Default(true) bool copyPrevious,
  }) = RoutineEditorWeekAdded;

  const factory RoutineEditorEvent.weekRemoved(int weekIndex) =
      RoutineEditorWeekRemoved;

  const factory RoutineEditorEvent.weekRenamed(int weekIndex, String name) =
      RoutineEditorWeekRenamed;

  const factory RoutineEditorEvent.dayAdded(int weekIndex, int dayNumber) =
      RoutineEditorDayAdded;

  const factory RoutineEditorEvent.dayRemoved(int weekIndex, int dayIndex) =
      RoutineEditorDayRemoved;

  const factory RoutineEditorEvent.dayRenamed(
    int weekIndex,
    int dayIndex,
    String name,
  ) = RoutineEditorDayRenamed;

  const factory RoutineEditorEvent.exerciseAdded(
    int weekIndex,
    int dayIndex,
    Exercise exercise,
  ) = RoutineEditorExerciseAdded;

  /// Sustituye un ejercicio por otro conservando series, repeticiones y descanso.
  const factory RoutineEditorEvent.exerciseReplaced(
    int weekIndex,
    int dayIndex,
    int exerciseIndex,
    Exercise exercise,
  ) = RoutineEditorExerciseReplaced;

  const factory RoutineEditorEvent.exerciseRemoved(
    int weekIndex,
    int dayIndex,
    int exerciseIndex,
  ) = RoutineEditorExerciseRemoved;

  /// Sube ([up] = true) o baja un ejercicio dentro de su día.
  const factory RoutineEditorEvent.exerciseMoved(
    int weekIndex,
    int dayIndex,
    int exerciseIndex, {
    required bool up,
  }) = RoutineEditorExerciseMoved;

  const factory RoutineEditorEvent.exerciseParametersChanged(
    int weekIndex,
    int dayIndex,
    int exerciseIndex,
    ExerciseParameters parameters,
  ) = RoutineEditorExerciseParametersChanged;

  // ---------------------------------------------------------- acciones
  const factory RoutineEditorEvent.refineRequested() =
      RoutineEditorRefineRequested;

  const factory RoutineEditorEvent.saveRequested() = RoutineEditorSaveRequested;
}
