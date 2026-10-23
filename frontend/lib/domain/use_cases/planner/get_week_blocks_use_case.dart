import '../../models/planner/calendar_block.dart';
import '../../models/planner/planner_week.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Bloques de la semana que empieza en [weekStart].
abstract interface class GetWeekBlocksUseCaseContract {
  Future<AppResult<List<CalendarBlock>>> call(DateTime weekStart);
}

class GetWeekBlocksUseCase implements GetWeekBlocksUseCaseContract {
  const GetWeekBlocksUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<List<CalendarBlock>>> call(DateTime weekStart) =>
      _repository.getBlocks(from: weekStart, to: PlannerWeek.endOf(weekStart));
}
