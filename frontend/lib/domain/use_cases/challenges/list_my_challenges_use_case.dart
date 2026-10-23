import '../../models/challenges/challenge_page.dart';
import '../../models/challenges/challenge_query.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Lista los retos propios con filtros y paginación.
abstract interface class ListMyChallengesUseCaseContract {
  Future<AppResult<ChallengePage>> call({
    required ChallengeQuery query,
    int page = 0,
    int size = 20,
  });
}

class ListMyChallengesUseCase implements ListMyChallengesUseCaseContract {
  const ListMyChallengesUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<ChallengePage>> call({
    required ChallengeQuery query,
    int page = 0,
    int size = 20,
  }) => _repository.listMine(query: query, page: page, size: size);
}
