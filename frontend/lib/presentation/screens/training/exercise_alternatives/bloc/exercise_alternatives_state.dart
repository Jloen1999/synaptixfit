part of 'exercise_alternatives_bloc.dart';

@freezed
abstract class ExerciseAlternativesState with _$ExerciseAlternativesState {
  const factory ExerciseAlternativesState({
    @Default(true) bool loading,
    @Default(<Exercise>[]) List<Exercise> alternatives,
    AppError? error,
  }) = _ExerciseAlternativesState;
}
