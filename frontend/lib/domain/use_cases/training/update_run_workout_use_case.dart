import '../../models/result/app_result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// Cambia el nombre y los pasos de un entreno de carrera.
abstract interface class UpdateRunWorkoutUseCaseContract {
  Future<AppResult<RunWorkout>> call(RunWorkout workout);
}

class UpdateRunWorkoutUseCase implements UpdateRunWorkoutUseCaseContract {
  const UpdateRunWorkoutUseCase(this._repository);

  final RunRepositoryContract _repository;

  @override
  Future<AppResult<RunWorkout>> call(RunWorkout workout) =>
      _repository.updateWorkout(workout);
}
