import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Salta un día de la rutina: deja de proponerse y sale del calendario.
abstract interface class SkipRoutineDayUseCaseContract {
  Future<AppResult<Routine>> call(String routineId, String dayId);
}

class SkipRoutineDayUseCase implements SkipRoutineDayUseCaseContract {
  const SkipRoutineDayUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String routineId, String dayId) =>
      _repository.skipDay(routineId, dayId);
}
