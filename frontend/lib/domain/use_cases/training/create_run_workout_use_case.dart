import '../../models/result/app_result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// Crea un entreno de carrera (desde cero o desde una plantilla).
abstract interface class CreateRunWorkoutUseCaseContract {
  Future<AppResult<RunWorkout>> call(RunWorkout workout);
}

class CreateRunWorkoutUseCase implements CreateRunWorkoutUseCaseContract {
  const CreateRunWorkoutUseCase(this._repository);

  final RunRepositoryContract _repository;

  @override
  Future<AppResult<RunWorkout>> call(RunWorkout workout) =>
      _repository.createWorkout(workout);
}
