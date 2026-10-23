import '../../models/challenges/challenge_progress_entry.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Historial de progreso manual de un reto.
abstract interface class ListChallengeProgressUseCaseContract {
  Future<AppResult<List<ChallengeProgressEntry>>> call(String challengeId);
}

class ListChallengeProgressUseCase
    implements ListChallengeProgressUseCaseContract {
  const ListChallengeProgressUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<List<ChallengeProgressEntry>>> call(String challengeId) =>
      _repository.progressHistory(challengeId);
}
