part of 'run_workout_editor_bloc.dart';

@freezed
abstract class RunWorkoutEditorState with _$RunWorkoutEditorState {
  const factory RunWorkoutEditorState({
    @Default(true) bool loading,
    AppError? error,
    String? workoutId,
    @Default('') String name,
    String? templateCode,
    @Default(<RunStepGroup>[]) List<RunStepGroup> groups,
    @Default(false) bool saving,
    @Default(false) bool saved,
    AppError? actionError,
  }) = _RunWorkoutEditorState;
}
