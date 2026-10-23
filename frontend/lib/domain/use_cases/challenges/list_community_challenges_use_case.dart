import '../../enums/challenge_type.dart';
import '../../models/challenges/challenge_page.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Retos activos visibles de otros usuarios.
abstract interface class ListCommunityChallengesUseCaseContract {
  Future<AppResult<ChallengePage>> call({
    ChallengeType? type,
    String? search,
    int page = 0,
    int size = 20,
  });
}

class ListCommunityChallengesUseCase
    implements ListCommunityChallengesUseCaseContract {
  const ListCommunityChallengesUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<ChallengePage>> call({
    ChallengeType? type,
    String? search,
    int page = 0,
    int size = 20,
  }) =>
      _repository.community(type: type, search: search, page: page, size: size);
}
