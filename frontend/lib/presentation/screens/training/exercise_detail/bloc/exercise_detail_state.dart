part of 'exercise_detail_bloc.dart';

@freezed
sealed class ExerciseDetailState with _$ExerciseDetailState {
  const factory ExerciseDetailState.loading() = ExerciseDetailLoading;

  /// [credits]: quién hizo la foto y el vídeo (ADR 0056); vacía si no hay
  /// que atribuir o no se pudo leer (la ficha sale igual).
  const factory ExerciseDetailState.loaded(
    Exercise exercise, {
    @Default(<MediaCredit>[]) List<MediaCredit> credits,
  }) = ExerciseDetailLoaded;

  const factory ExerciseDetailState.failure(AppError error) =
      ExerciseDetailFailure;
}
