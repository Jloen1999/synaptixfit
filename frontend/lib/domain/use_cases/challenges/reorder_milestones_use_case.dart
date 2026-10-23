import '../../models/challenges/challenge.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Cambia el orden de las tareas de un reto.
abstract interface class ReorderMilestonesUseCaseContract {
  Future<AppResult<Challenge>> call(
    String challengeId,
    List<String> milestoneIds,
  );
}

class ReorderMilestonesUseCase implements ReorderMilestonesUseCaseContract {
  const ReorderMilestonesUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<Challenge>> call(
    String challengeId,
    List<String> milestoneIds,
  ) => _repository.reorderMilestones(challengeId, milestoneIds);
}
