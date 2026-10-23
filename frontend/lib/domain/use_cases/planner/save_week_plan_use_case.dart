import '../../models/planner/weekly_planning.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Guarda el plan de la semana (da XP la primera vez).
abstract interface class SaveWeekPlanUseCaseContract {
  Future<AppResult<SavedPlan>> call(DateTime weekStart);
}

class SaveWeekPlanUseCase implements SaveWeekPlanUseCaseContract {
  const SaveWeekPlanUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<SavedPlan>> call(DateTime weekStart) =>
      _repository.savePlan(weekStart);
}
