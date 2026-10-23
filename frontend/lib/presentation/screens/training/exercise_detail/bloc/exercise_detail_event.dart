part of 'exercise_detail_bloc.dart';

@freezed
sealed class ExerciseDetailEvent with _$ExerciseDetailEvent {
  const factory ExerciseDetailEvent.started(String exerciseId) =
      ExerciseDetailStarted;
}
