import '../../models/planner/calendar_feed.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Crea el enlace de suscripción (el anterior deja de funcionar).
abstract interface class CreateCalendarFeedUseCaseContract {
  Future<AppResult<CalendarFeedLink>> call();
}

class CreateCalendarFeedUseCase implements CreateCalendarFeedUseCaseContract {
  const CreateCalendarFeedUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<CalendarFeedLink>> call() =>
      _repository.createCalendarFeed();
}
