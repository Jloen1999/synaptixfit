import '../../models/result/app_result.dart';
import '../../models/training/exercise.dart';
import '../../repositories/exercise_repository_contract.dart';

/// Detalle de un ejercicio del catálogo.
abstract interface class GetExerciseUseCaseContract {
  Future<AppResult<Exercise>> call(String exerciseId);
}

class GetExerciseUseCase implements GetExerciseUseCaseContract {
  const GetExerciseUseCase(this._repository);

  final ExerciseRepositoryContract _repository;

  @override
  Future<AppResult<Exercise>> call(String exerciseId) =>
      _repository.getExercise(exerciseId);
}
