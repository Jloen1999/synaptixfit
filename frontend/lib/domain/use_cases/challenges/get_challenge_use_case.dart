import '../../models/challenges/challenge.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Detalle de un reto propio o visible.
abstract interface class GetChallengeUseCaseContract {
  Future<AppResult<Challenge>> call(String challengeId);
}

class GetChallengeUseCase implements GetChallengeUseCaseContract {
  const GetChallengeUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<Challenge>> call(String challengeId) =>
      _repository.get(challengeId);
}
