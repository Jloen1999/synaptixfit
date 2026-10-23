import '../../models/planner/weekly_planning.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Balance estudio/deporte de la semana.
abstract interface class GetWeekBalanceUseCaseContract {
  Future<AppResult<WeekBalance>> call(DateTime weekStart);
}

class GetWeekBalanceUseCase implements GetWeekBalanceUseCaseContract {
  const GetWeekBalanceUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<WeekBalance>> call(DateTime weekStart) =>
      _repository.getBalance(weekStart);
}
