import '../../models/result/app_result.dart';
import '../../models/training/exercise.dart';
import '../../repositories/exercise_repository_contract.dart';

/// Ejercicios que pueden sustituir a otro (mismo músculo principal).
abstract interface class GetExerciseAlternativesUseCaseContract {
  Future<AppResult<List<Exercise>>> call(String exerciseId);
}

class GetExerciseAlternativesUseCase
    implements GetExerciseAlternativesUseCaseContract {
  const GetExerciseAlternativesUseCase(this._repository);

  final ExerciseRepositoryContract _repository;

  @override
  Future<AppResult<List<Exercise>>> call(String exerciseId) =>
      _repository.getAlternatives(exerciseId);
}
