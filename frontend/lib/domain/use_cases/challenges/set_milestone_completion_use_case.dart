import '../../models/challenges/challenge_outcome.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Completa o descompleta una tarea (con su XP y desbloqueos).
abstract interface class SetMilestoneCompletionUseCaseContract {
  Future<AppResult<ChallengeOutcome>> call(
    String challengeId,
    String milestoneId, {
    required bool completed,
  });
}

class SetMilestoneCompletionUseCase
    implements SetMilestoneCompletionUseCaseContract {
  const SetMilestoneCompletionUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<ChallengeOutcome>> call(
    String challengeId,
    String milestoneId, {
    required bool completed,
  }) => _repository.setMilestoneCompleted(
    challengeId,
    milestoneId,
    completed: completed,
  );
}
