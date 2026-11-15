import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Acepta la invitación a un reto con amigos (o vuelve tras salir).
abstract interface class JoinFriendChallengeUseCaseContract {
  Future<AppResult<FriendChallenge>> call(String id);
}

/// Implementa [JoinFriendChallengeUseCaseContract] con [TogetherRepositoryContract].
class JoinFriendChallengeUseCase implements JoinFriendChallengeUseCaseContract {
  const JoinFriendChallengeUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<FriendChallenge>> call(String id) =>
      _repository.joinChallenge(id);
}
