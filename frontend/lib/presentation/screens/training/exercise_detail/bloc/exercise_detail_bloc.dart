import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/models/training/media_credit.dart';
import '../../../../../domain/use_cases/training/get_exercise_media_credits_use_case.dart';
import '../../../../../domain/use_cases/training/get_exercise_use_case.dart';

part 'exercise_detail_bloc.freezed.dart';
part 'exercise_detail_event.dart';
part 'exercise_detail_state.dart';

/// Detalle de un ejercicio del catálogo y el crédito de su foto y su vídeo
/// (ADR 0056), que se pide a la vez y, si falla, no impide ver la ficha.
class ExerciseDetailBloc
    extends Bloc<ExerciseDetailEvent, ExerciseDetailState> {
  ExerciseDetailBloc({required this._getExercise, required this._getCredits})
    : super(const ExerciseDetailState.loading()) {
    on<ExerciseDetailStarted>((event, emit) async {
      emit(const ExerciseDetailState.loading());
      final creditsFuture = _getCredits(event.exerciseId);
      final result = await _getExercise(event.exerciseId);
      final credits = (await creditsFuture).valueOrNull ?? const [];
      emit(
        result.fold(
          (exercise) => ExerciseDetailState.loaded(exercise, credits: credits),
          ExerciseDetailState.failure,
        ),
      );
    });
  }

  final GetExerciseUseCaseContract _getExercise;
  final GetExerciseMediaCreditsUseCaseContract _getCredits;
}
