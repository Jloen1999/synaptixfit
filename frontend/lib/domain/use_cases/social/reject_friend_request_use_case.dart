import '../../models/result/app_result.dart';
import '../../models/social/friendship.dart';
import '../../repositories/friendship_repository_contract.dart';

/// Rechaza una solicitud recibida.
abstract interface class RejectFriendRequestUseCaseContract {
  Future<AppResult<Friendship>> call({required String friendshipId});
}

class RejectFriendRequestUseCase implements RejectFriendRequestUseCaseContract {
  const RejectFriendRequestUseCase(this._repository);

  final FriendshipRepositoryContract _repository;

  @override
  Future<AppResult<Friendship>> call({required String friendshipId}) =>
      _repository.reject(friendshipId);
}
