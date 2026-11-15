import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Detalle de un reto con amigos con su tablón.
abstract interface class GetFriendChallengeUseCaseContract {
  Future<AppResult<FriendChallenge>> call(String id);
}

/// Implementa [GetFriendChallengeUseCaseContract] con [TogetherRepositoryContract].
class GetFriendChallengeUseCase implements GetFriendChallengeUseCaseContract {
  const GetFriendChallengeUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<FriendChallenge>> call(String id) =>
      _repository.challenge(id);
}
