import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/run_repository_contract.dart';

/// Borra un entreno de carrera (los eventos ya puestos se quedan).
abstract interface class DeleteRunWorkoutUseCaseContract {
  Future<AppResult<Unit>> call(String workoutId);
}

class DeleteRunWorkoutUseCase implements DeleteRunWorkoutUseCaseContract {
  const DeleteRunWorkoutUseCase(this._repository);

  final RunRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String workoutId) =>
      _repository.deleteWorkout(workoutId);
}
