import '../../models/result/app_result.dart';
import '../../models/training/exercise_guide.dart';
import '../../repositories/exercise_repository_contract.dart';

/// «Las claves» y «Errores comunes» de un ejercicio (vacío si no hay).
abstract interface class GetExerciseTipsUseCaseContract {
  Future<AppResult<ExerciseTips>> call(String exerciseId);
}

class GetExerciseTipsUseCase implements GetExerciseTipsUseCaseContract {
  const GetExerciseTipsUseCase(this._repository);

  final ExerciseRepositoryContract _repository;

  @override
  Future<AppResult<ExerciseTips>> call(String exerciseId) =>
      _repository.getTips(exerciseId);
}
