part of 'exercise_guide_bloc.dart';

@freezed
sealed class ExerciseGuideEvent with _$ExerciseGuideEvent {
  const factory ExerciseGuideEvent.started(String exerciseId) =
      ExerciseGuideStarted;

  /// Guarda la nota; vacía, la borra.
  const factory ExerciseGuideEvent.noteSaved(String text) =
      ExerciseGuideNoteSaved;
}
