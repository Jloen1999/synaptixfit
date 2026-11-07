import '../../models/result/app_result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// «Tus entrenos de carrera».
abstract interface class ListRunWorkoutsUseCaseContract {
  Future<AppResult<List<RunWorkout>>> call();
}

class ListRunWorkoutsUseCase implements ListRunWorkoutsUseCaseContract {
  const ListRunWorkoutsUseCase(this._repository);

  final RunRepositoryContract _repository;

  @override
  Future<AppResult<List<RunWorkout>>> call() => _repository.listWorkouts();
}
