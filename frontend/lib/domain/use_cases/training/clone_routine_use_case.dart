import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Clona una rutina de la comunidad.
abstract interface class CloneRoutineUseCaseContract {
  Future<AppResult<Routine>> call(String routineId);
}

class CloneRoutineUseCase implements CloneRoutineUseCaseContract {
  const CloneRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String routineId) =>
      _repository.cloneRoutine(routineId);
}
