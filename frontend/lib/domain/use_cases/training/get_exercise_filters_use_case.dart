import '../../models/result/app_result.dart';
import '../../models/training/exercise.dart';
import '../../repositories/exercise_repository_contract.dart';

/// Valores disponibles para los filtros del catálogo.
abstract interface class GetExerciseFiltersUseCaseContract {
  Future<AppResult<ExerciseFilterOptions>> call();
}

class GetExerciseFiltersUseCase implements GetExerciseFiltersUseCaseContract {
  const GetExerciseFiltersUseCase(this._repository);

  final ExerciseRepositoryContract _repository;

  @override
  Future<AppResult<ExerciseFilterOptions>> call() => _repository.getFilters();
}
