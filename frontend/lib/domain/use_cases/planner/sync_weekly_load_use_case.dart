import '../../models/planner/weekly_planning.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Recalcula la carga de la semana.
abstract interface class SyncWeeklyLoadUseCaseContract {
  Future<AppResult<WeeklyLoadSync>> call(DateTime weekStart);
}

class SyncWeeklyLoadUseCase implements SyncWeeklyLoadUseCaseContract {
  const SyncWeeklyLoadUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<WeeklyLoadSync>> call(DateTime weekStart) =>
      _repository.syncWeeklyLoad(weekStart);
}
