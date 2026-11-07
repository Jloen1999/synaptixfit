part of 'run_workout_editor_bloc.dart';

@freezed
sealed class RunWorkoutEditorEvent with _$RunWorkoutEditorEvent {
  /// [defaultName]: el de la plantilla (o uno genérico) ya en el idioma.
  const factory RunWorkoutEditorEvent.started({
    String? workoutId,
    RunWorkout? workout,
    String? templateCode,
    required String defaultName,
  }) = RunWorkoutEditorStarted;

  const factory RunWorkoutEditorEvent.nameChanged(String name) =
      RunWorkoutEditorNameChanged;

  const factory RunWorkoutEditorEvent.groupAdded() = RunWorkoutEditorGroupAdded;

  const factory RunWorkoutEditorEvent.groupRemoved(int index) =
      RunWorkoutEditorGroupRemoved;

  const factory RunWorkoutEditorEvent.repeatChanged(int index, int repeat) =
      RunWorkoutEditorRepeatChanged;

  const factory RunWorkoutEditorEvent.stepAdded(int index) =
      RunWorkoutEditorStepAdded;

  const factory RunWorkoutEditorEvent.stepRemoved(int index, int step) =
      RunWorkoutEditorStepRemoved;

  const factory RunWorkoutEditorEvent.stepChanged(
    int index,
    int step,
    RunStep value,
  ) = RunWorkoutEditorStepChanged;

  const factory RunWorkoutEditorEvent.saveRequested() =
      RunWorkoutEditorSaveRequested;
}
