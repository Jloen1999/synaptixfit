import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Recupera un día saltado (vuelve a estar pendiente).
abstract interface class UnskipRoutineDayUseCaseContract {
  Future<AppResult<Routine>> call(String routineId, String dayId);
}

class UnskipRoutineDayUseCase implements UnskipRoutineDayUseCaseContract {
  const UnskipRoutineDayUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String routineId, String dayId) =>
      _repository.unskipDay(routineId, dayId);
}
