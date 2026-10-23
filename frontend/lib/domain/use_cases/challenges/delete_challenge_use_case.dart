import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Borra un reto propio (resta la XP que había otorgado).
abstract interface class DeleteChallengeUseCaseContract {
  Future<AppResult<Unit>> call(String challengeId);
}

class DeleteChallengeUseCase implements DeleteChallengeUseCaseContract {
  const DeleteChallengeUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String challengeId) =>
      _repository.delete(challengeId);
}
