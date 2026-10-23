import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Quita un ejercicio planificado.
abstract interface class RemoveRoutineExerciseUseCaseContract {
  Future<AppResult<Routine>> call(String routineId, String plannedExerciseId);
}

class RemoveRoutineExerciseUseCase
    implements RemoveRoutineExerciseUseCaseContract {
  const RemoveRoutineExerciseUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String routineId, String plannedExerciseId) =>
      _repository.removeExercise(routineId, plannedExerciseId);
}
