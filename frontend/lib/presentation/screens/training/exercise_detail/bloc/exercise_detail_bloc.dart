import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/use_cases/training/get_exercise_use_case.dart';

part 'exercise_detail_bloc.freezed.dart';
part 'exercise_detail_event.dart';
part 'exercise_detail_state.dart';

/// Detalle de un ejercicio del catálogo.
class ExerciseDetailBloc
    extends Bloc<ExerciseDetailEvent, ExerciseDetailState> {
  ExerciseDetailBloc({required this._getExercise})
    : super(const ExerciseDetailState.loading()) {
    on<ExerciseDetailStarted>((event, emit) async {
      emit(const ExerciseDetailState.loading());
      final result = await _getExercise(event.exerciseId);
      emit(
        result.fold(ExerciseDetailState.loaded, ExerciseDetailState.failure),
      );
    });
  }

  final GetExerciseUseCaseContract _getExercise;
}
