import '../../models/planner/block_draft.dart';
import '../../models/planner/calendar_block.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Reparte una rutina completa en los días elegidos.
abstract interface class DistributeRoutineUseCaseContract {
  Future<AppResult<List<CalendarBlock>>> call(RoutineDistribution request);
}

class DistributeRoutineUseCase implements DistributeRoutineUseCaseContract {
  const DistributeRoutineUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<List<CalendarBlock>>> call(RoutineDistribution request) =>
      _repository.distributeRoutine(request);
}
