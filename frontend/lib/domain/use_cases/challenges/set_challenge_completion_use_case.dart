import '../../models/challenges/challenge_outcome.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Completa o descompleta un reto (con su XP).
abstract interface class SetChallengeCompletionUseCaseContract {
  Future<AppResult<ChallengeOutcome>> call(
    String challengeId, {
    required bool completed,
  });
}

class SetChallengeCompletionUseCase
    implements SetChallengeCompletionUseCaseContract {
  const SetChallengeCompletionUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<ChallengeOutcome>> call(
    String challengeId, {
    required bool completed,
  }) => _repository.setCompleted(challengeId, completed: completed);
}
