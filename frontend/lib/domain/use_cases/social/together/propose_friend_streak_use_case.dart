import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Propone una racha a un amigo mutuo.
abstract interface class ProposeFriendStreakUseCaseContract {
  Future<AppResult<FriendStreak>> call(String friendId);
}

/// Implementa [ProposeFriendStreakUseCaseContract] con [TogetherRepositoryContract].
class ProposeFriendStreakUseCase implements ProposeFriendStreakUseCaseContract {
  const ProposeFriendStreakUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<FriendStreak>> call(String friendId) =>
      _repository.proposeStreak(friendId);
}
