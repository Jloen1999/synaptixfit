import '../../models/planner/weekly_planning.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Bloques y entregas de [from, to) en orden.
abstract interface class GetTimelineUseCaseContract {
  Future<AppResult<List<TimelineEntry>>> call({
    required DateTime from,
    required DateTime to,
  });
}

class GetTimelineUseCase implements GetTimelineUseCaseContract {
  const GetTimelineUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<List<TimelineEntry>>> call({
    required DateTime from,
    required DateTime to,
  }) => _repository.getTimeline(from: from, to: to);
}
