import '../../models/result/app_result.dart';
import '../../models/training/exercise.dart';
import '../../models/training/training_page.dart';
import '../../repositories/exercise_repository_contract.dart';

/// Busca en el catálogo de ejercicios con filtros y paginación.
abstract interface class SearchExercisesUseCaseContract {
  Future<AppResult<TrainingPage<Exercise>>> call(
    ExerciseSearchCriteria criteria, {
    int page = 0,
    int size = 20,
  });
}

class SearchExercisesUseCase implements SearchExercisesUseCaseContract {
  const SearchExercisesUseCase(this._repository);

  final ExerciseRepositoryContract _repository;

  @override
  Future<AppResult<TrainingPage<Exercise>>> call(
    ExerciseSearchCriteria criteria, {
    int page = 0,
    int size = 20,
  }) => _repository.search(criteria, page: page, size: size);
}
