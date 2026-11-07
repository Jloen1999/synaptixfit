import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/exercise_progress.dart';
import '../../../../../domain/use_cases/training/get_exercise_progress_use_case.dart';

part 'exercise_progress_bloc.freezed.dart';
part 'exercise_progress_event.dart';
part 'exercise_progress_state.dart';

/// Evolución de un ejercicio para su gráfica (los puntos los da el servidor
/// con [GetExerciseProgressUseCaseContract]); la pinta `ExerciseProgressSection`.
class ExerciseProgressBloc
    extends Bloc<ExerciseProgressEvent, ExerciseProgressState> {
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
