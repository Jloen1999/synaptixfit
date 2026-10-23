part of 'exercise_alternatives_bloc.dart';

@freezed
sealed class ExerciseAlternativesEvent with _$ExerciseAlternativesEvent {
  const factory ExerciseAlternativesEvent.started(String exerciseId) =
      ExerciseAlternativesStarted;
}
