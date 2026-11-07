import '../../models/result/app_result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// Plantillas de entreno de carrera listas para usar.
abstract interface class ListRunWorkoutTemplatesUseCaseContract {
  Future<AppResult<List<RunWorkout>>> call();
}

class ListRunWorkoutTemplatesUseCase
    implements ListRunWorkoutTemplatesUseCaseContract {
  const ListRunWorkoutTemplatesUseCase(this._repository);

  final RunRepositoryContract _repository;

  @override
  Future<AppResult<List<RunWorkout>>> call() => _repository.listTemplates();
}
