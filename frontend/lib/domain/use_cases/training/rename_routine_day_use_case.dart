import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Renombra un día.
abstract interface class RenameRoutineDayUseCaseContract {
  Future<AppResult<Routine>> call(String routineId, String dayId, String name);
}

class RenameRoutineDayUseCase implements RenameRoutineDayUseCaseContract {
  const RenameRoutineDayUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(
    String routineId,
    String dayId,
    String name,
  ) => _repository.renameDay(routineId, dayId, name);
}
