import '../../../enums/together_enums.dart';
import '../../../models/result/app_result.dart';
import '../../../models/result/result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Pone o cambia una reacción fija a lo que sumó alguien un día.
abstract interface class ReactToFriendChallengeUseCaseContract {
  Future<AppResult<Unit>> call(
    String challengeId, {
    required String recipientId,
    required DateTime day,
    required TogetherReaction reaction,
  });
}

/// Implementa [ReactToFriendChallengeUseCaseContract] con [TogetherRepositoryContract].
class ReactToFriendChallengeUseCase
    implements ReactToFriendChallengeUseCaseContract {
  const ReactToFriendChallengeUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(
    String challengeId, {
    required String recipientId,
    required DateTime day,
    required TogetherReaction reaction,
  }) => _repository.react(
    challengeId,
    recipientId: recipientId,
    day: day,
    reaction: reaction,
  );
}
