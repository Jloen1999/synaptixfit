import '../../models/planner/weekly_planning.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Carga académica guardada de la semana (o `null`).
abstract interface class GetWeeklyLoadUseCaseContract {
  Future<AppResult<WeeklyLoad?>> call(DateTime weekStart);
}

class GetWeeklyLoadUseCase implements GetWeeklyLoadUseCaseContract {
  const GetWeeklyLoadUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<WeeklyLoad?>> call(DateTime weekStart) =>
      _repository.getWeeklyLoad(weekStart);
}
