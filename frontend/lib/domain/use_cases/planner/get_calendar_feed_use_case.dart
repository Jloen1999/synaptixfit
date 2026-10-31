import '../../models/planner/calendar_feed.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Si hay un enlace de suscripción al calendario activo y desde cuándo.
abstract interface class GetCalendarFeedUseCaseContract {
  Future<AppResult<CalendarFeedStatus>> call();
}

class GetCalendarFeedUseCase implements GetCalendarFeedUseCaseContract {
  const GetCalendarFeedUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<CalendarFeedStatus>> call() => _repository.getCalendarFeed();
}
