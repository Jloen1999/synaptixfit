import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Elimina una semana.
abstract interface class DeleteRoutineWeekUseCaseContract {
  Future<AppResult<Routine>> call(String routineId, String weekId);
}

class DeleteRoutineWeekUseCase implements DeleteRoutineWeekUseCaseContract {
  const DeleteRoutineWeekUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String routineId, String weekId) =>
      _repository.deleteWeek(routineId, weekId);
}
