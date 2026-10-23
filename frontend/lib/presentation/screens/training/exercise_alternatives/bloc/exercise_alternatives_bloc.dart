import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/use_cases/training/get_exercise_alternatives_use_case.dart';

part 'exercise_alternatives_bloc.freezed.dart';
part 'exercise_alternatives_event.dart';
part 'exercise_alternatives_state.dart';

/// Hoja «Cambiar ejercicio»: carga los que trabajan el mismo músculo, ordenados
/// por el servidor del más parecido al menos.
class ExerciseAlternativesBloc
    extends Bloc<ExerciseAlternativesEvent, ExerciseAlternativesState> {
  ExerciseAlternativesBloc({required this._getAlternatives})
    : super(const ExerciseAlternativesState()) {
    on<ExerciseAlternativesStarted>((event, emit) async {
      emit(const ExerciseAlternativesState());
      final result = await _getAlternatives(event.exerciseId);
      emit(
        result.fold(
          (list) =>
              ExerciseAlternativesState(loading: false, alternatives: list),
          (error) => ExerciseAlternativesState(loading: false, error: error),
        ),
      );
    });
  }

  final GetExerciseAlternativesUseCaseContract _getAlternatives;
}
