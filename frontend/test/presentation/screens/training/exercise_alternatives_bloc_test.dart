import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/exercise.dart';
import 'package:synaptixfit/domain/use_cases/training/get_exercise_alternatives_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/exercise_alternatives/bloc/exercise_alternatives_bloc.dart';

import 'training_fixtures.dart';

class _Alternatives extends Mock
    implements GetExerciseAlternativesUseCaseContract {}

void main() {
  late _Alternatives alternatives;

  setUp(() => alternatives = _Alternatives());

  ExerciseAlternativesBloc build() =>
      ExerciseAlternativesBloc(getAlternatives: alternatives);

  blocTest<ExerciseAlternativesBloc, ExerciseAlternativesState>(
    'carga las alternativas que ordena el servidor',
    setUp: () => when(() => alternatives('ex-squat')).thenAnswer(
      (_) async =>
          const Success<List<Exercise>, AppError>([TrainingFixtures.run]),
    ),
    build: build,
    act: (bloc) =>
        bloc.add(const ExerciseAlternativesEvent.started('ex-squat')),
    expect: () => const [
      ExerciseAlternativesState(),
      ExerciseAlternativesState(
        loading: false,
        alternatives: [TrainingFixtures.run],
      ),
    ],
  );

  blocTest<ExerciseAlternativesBloc, ExerciseAlternativesState>(
    'un error se muestra y al reintentar vuelve a cargar',
    setUp: () {
      var calls = 0;
      when(() => alternatives('ex-squat')).thenAnswer(
        (_) async => calls++ == 0
            ? const Failure<List<Exercise>, AppError>(AppError.network())
            : const Success<List<Exercise>, AppError>([]),
      );
    },
    build: build,
    act: (bloc) async {
      bloc.add(const ExerciseAlternativesEvent.started('ex-squat'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ExerciseAlternativesEvent.started('ex-squat'));
    },
    expect: () => const [
      ExerciseAlternativesState(),
      ExerciseAlternativesState(loading: false, error: AppError.network()),
      ExerciseAlternativesState(),
      ExerciseAlternativesState(loading: false),
    ],
  );
}
