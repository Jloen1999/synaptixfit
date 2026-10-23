import '../../models/result/app_result.dart';
import '../../models/social/friendship.dart';
import '../../repositories/friendship_repository_contract.dart';

/// Acepta una solicitud recibida.
abstract interface class AcceptFriendRequestUseCaseContract {
  Future<AppResult<Friendship>> call({required String friendshipId});
}

class AcceptFriendRequestUseCase implements AcceptFriendRequestUseCaseContract {
  const AcceptFriendRequestUseCase(this._repository);

  final FriendshipRepositoryContract _repository;

  @override
  Future<AppResult<Friendship>> call({required String friendshipId}) =>
      _repository.accept(friendshipId);
}
