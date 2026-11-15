import '../../../enums/together_enums.dart';
import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Crea un reto con amigos mutuos desde una plantilla e invita a los amigos.
abstract interface class CreateFriendChallengeUseCaseContract {
  Future<AppResult<FriendChallenge>> call({
    required String templateId,
    required int days,
    required FriendChallengeMode mode,
    required List<String> friendIds,
  });
}

/// Implementa [CreateFriendChallengeUseCaseContract] con [TogetherRepositoryContract].
class CreateFriendChallengeUseCase
    implements CreateFriendChallengeUseCaseContract {
  const CreateFriendChallengeUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<FriendChallenge>> call({
    required String templateId,
    required int days,
    required FriendChallengeMode mode,
    required List<String> friendIds,
  }) => _repository.createChallenge(
    templateId: templateId,
    days: days,
    mode: mode,
    friendIds: friendIds,
  );
}
