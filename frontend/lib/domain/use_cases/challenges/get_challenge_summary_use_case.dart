import '../../models/challenges/challenge_summary.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Recuento de retos activos, completados y vencidos.
abstract interface class GetChallengeSummaryUseCaseContract {
  Future<AppResult<ChallengeSummary>> call();
}

class GetChallengeSummaryUseCase implements GetChallengeSummaryUseCaseContract {
  const GetChallengeSummaryUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<ChallengeSummary>> call() => _repository.summary();
}
