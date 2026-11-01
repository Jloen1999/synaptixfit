import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Repite el ciclo de una rutina: avance a cero, desde hoy y en curso.
abstract interface class RestartRoutineUseCaseContract {
  Future<AppResult<Routine>> call(String routineId);
}

class RestartRoutineUseCase implements RestartRoutineUseCaseContract {
  const RestartRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String routineId) =>
      _repository.restartRoutine(routineId);
}
