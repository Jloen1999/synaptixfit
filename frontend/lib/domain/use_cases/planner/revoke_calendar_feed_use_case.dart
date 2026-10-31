import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Desactiva el enlace de suscripción.
abstract interface class RevokeCalendarFeedUseCaseContract {
  Future<AppResult<Unit>> call();
}

class RevokeCalendarFeedUseCase implements RevokeCalendarFeedUseCaseContract {
  const RevokeCalendarFeedUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call() => _repository.revokeCalendarFeed();
}
