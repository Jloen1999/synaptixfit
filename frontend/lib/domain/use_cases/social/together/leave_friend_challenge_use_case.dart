import '../../../models/result/app_result.dart';
import '../../../models/result/result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Sale de un reto con amigos (se vuelve con «Deshacer»).
abstract interface class LeaveFriendChallengeUseCaseContract {
  Future<AppResult<Unit>> call(String id);
}

/// Implementa [LeaveFriendChallengeUseCaseContract] con [TogetherRepositoryContract].
class LeaveFriendChallengeUseCase
    implements LeaveFriendChallengeUseCaseContract {
  const LeaveFriendChallengeUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String id) => _repository.leaveChallenge(id);
}
