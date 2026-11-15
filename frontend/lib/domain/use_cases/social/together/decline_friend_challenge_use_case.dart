import '../../../models/result/app_result.dart';
import '../../../models/result/result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Dice que no a la invitación a un reto con amigos.
abstract interface class DeclineFriendChallengeUseCaseContract {
  Future<AppResult<Unit>> call(String id);
}

/// Implementa [DeclineFriendChallengeUseCaseContract] con [TogetherRepositoryContract].
class DeclineFriendChallengeUseCase
    implements DeclineFriendChallengeUseCaseContract {
  const DeclineFriendChallengeUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String id) => _repository.declineChallenge(id);
}
