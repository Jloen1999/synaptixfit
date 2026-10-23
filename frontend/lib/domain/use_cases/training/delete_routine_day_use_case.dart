import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Elimina un día.
abstract interface class DeleteRoutineDayUseCaseContract {
  Future<AppResult<Routine>> call(String routineId, String dayId);
}

class DeleteRoutineDayUseCase implements DeleteRoutineDayUseCaseContract {
  const DeleteRoutineDayUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String routineId, String dayId) =>
      _repository.deleteDay(routineId, dayId);
}
