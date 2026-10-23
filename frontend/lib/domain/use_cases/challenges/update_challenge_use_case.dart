import '../../models/challenges/challenge.dart';
import '../../models/challenges/challenge_draft.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Cambia los datos básicos de un reto propio.
abstract interface class UpdateChallengeUseCaseContract {
  Future<AppResult<Challenge>> call(
    String challengeId,
    ChallengeChanges changes,
  );
}

class UpdateChallengeUseCase implements UpdateChallengeUseCaseContract {
  const UpdateChallengeUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<Challenge>> call(
    String challengeId,
    ChallengeChanges changes,
  ) => _repository.update(challengeId, changes);
}
