part of 'exercise_progress_bloc.dart';

enum ExerciseProgressStatus { loading, ready, failure }

@freezed
abstract class ExerciseProgressState with _$ExerciseProgressState {
  const factory ExerciseProgressState({
    @Default(ExerciseProgressStatus.loading) ExerciseProgressStatus status,
    @Default(<ExerciseProgressPoint>[]) List<ExerciseProgressPoint> points,
    AppError? error,
  }) = _ExerciseProgressState;

  const ExerciseProgressState._();

  ExerciseProgressPoint? get best => points.isEmpty
      ? null
      : points.reduce((a, b) => a.estimatedMaxKg >= b.estimatedMaxKg ? a : b);

  /// Cuánto ha subido el máximo estimado desde el primer día (puede ser 0).
  double get change => points.length < 2
      ? 0
      : points.last.estimatedMaxKg - points.first.estimatedMaxKg;
}
