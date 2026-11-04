import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/exercise_progress.dart';
import '../../../../../domain/use_cases/training/get_exercise_progress_use_case.dart';

part 'exercise_progress_bloc.freezed.dart';

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

/// Evento único: cargar (o recargar) la evolución de un ejercicio.
final class ExerciseProgressRequested {
  const ExerciseProgressRequested(this.exerciseId);

  final String exerciseId;
}

/// Evolución de un ejercicio para su gráfica (los puntos los da el servidor).
class ExerciseProgressBloc
    extends Bloc<ExerciseProgressRequested, ExerciseProgressState> {
  ExerciseProgressBloc({required this._get})
    : super(const ExerciseProgressState()) {
    on<ExerciseProgressRequested>((event, emit) async {
      emit(const ExerciseProgressState());
      final result = await _get(event.exerciseId);
      emit(switch (result) {
        Success(:final value) => ExerciseProgressState(
          status: ExerciseProgressStatus.ready,
          points: value,
        ),
        Failure(:final error) => ExerciseProgressState(
          status: ExerciseProgressStatus.failure,
          error: error,
        ),
      });
    });
  }

  final GetExerciseProgressUseCaseContract _get;
}
