part of 'exercise_detail_bloc.dart';

@freezed
sealed class ExerciseDetailState with _$ExerciseDetailState {
  const factory ExerciseDetailState.loading() = ExerciseDetailLoading;

  const factory ExerciseDetailState.loaded(Exercise exercise) =
      ExerciseDetailLoaded;

  const factory ExerciseDetailState.failure(AppError error) =
      ExerciseDetailFailure;
}
