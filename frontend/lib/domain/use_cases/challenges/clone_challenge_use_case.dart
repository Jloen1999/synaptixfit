import '../../models/challenges/challenge.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Copia un reto de otro usuario como reto propio privado.
abstract interface class CloneChallengeUseCaseContract {
  Future<AppResult<Challenge>> call(String challengeId);
}

class CloneChallengeUseCase implements CloneChallengeUseCaseContract {
  const CloneChallengeUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<Challenge>> call(String challengeId) =>
      _repository.clone(challengeId);
}
