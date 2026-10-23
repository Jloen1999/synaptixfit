import '../../models/challenges/pending_milestone.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Tareas pendientes de los retos activos.
abstract interface class ListPendingMilestonesUseCaseContract {
  Future<AppResult<List<PendingMilestone>>> call();
}

class ListPendingMilestonesUseCase
    implements ListPendingMilestonesUseCaseContract {
  const ListPendingMilestonesUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<List<PendingMilestone>>> call() =>
      _repository.pendingMilestones();
}
