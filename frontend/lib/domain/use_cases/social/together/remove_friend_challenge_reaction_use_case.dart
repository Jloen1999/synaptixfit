import '../../../models/result/app_result.dart';
import '../../../models/result/result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Quita mi reacción a una entrada del tablón.
abstract interface class RemoveFriendChallengeReactionUseCaseContract {
  Future<AppResult<Unit>> call(
    String challengeId, {
    required String recipientId,
    required DateTime day,
  });
}

/// Implementa [RemoveFriendChallengeReactionUseCaseContract] con [TogetherRepositoryContract].
class RemoveFriendChallengeReactionUseCase
    implements RemoveFriendChallengeReactionUseCaseContract {
  const RemoveFriendChallengeReactionUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(
    String challengeId, {
    required String recipientId,
    required DateTime day,
  }) => _repository.removeReaction(
    challengeId,
    recipientId: recipientId,
    day: day,
  );
}
