import '../../models/planner/calendar_block.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Pares de bloques solapados de la semana.
abstract interface class GetWeekConflictsUseCaseContract {
  Future<AppResult<List<BlockConflict>>> call(DateTime weekStart);
}

class GetWeekConflictsUseCase implements GetWeekConflictsUseCaseContract {
  const GetWeekConflictsUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<List<BlockConflict>>> call(DateTime weekStart) =>
      _repository.getConflicts(weekStart);
}
