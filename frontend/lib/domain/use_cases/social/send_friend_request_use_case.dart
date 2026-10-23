import '../../models/result/app_result.dart';
import '../../models/social/friendship.dart';
import '../../repositories/friendship_repository_contract.dart';

/// Envía una solicitud de amistad.
abstract interface class SendFriendRequestUseCaseContract {
  Future<AppResult<Friendship>> call({required String userId});
}

class SendFriendRequestUseCase implements SendFriendRequestUseCaseContract {
  const SendFriendRequestUseCase(this._repository);

  final FriendshipRepositoryContract _repository;

  @override
  Future<AppResult<Friendship>> call({required String userId}) =>
      _repository.sendRequest(userId);
}
