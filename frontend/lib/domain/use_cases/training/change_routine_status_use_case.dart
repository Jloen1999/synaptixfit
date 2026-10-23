import '../../enums/training_enums.dart';
import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Activa, pausa, completa o archiva una rutina.
abstract interface class ChangeRoutineStatusUseCaseContract {
  Future<AppResult<Routine>> call(String routineId, RoutineStatus status);
}

class ChangeRoutineStatusUseCase implements ChangeRoutineStatusUseCaseContract {
  const ChangeRoutineStatusUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String routineId, RoutineStatus status) =>
      _repository.changeStatus(routineId, status);
}
