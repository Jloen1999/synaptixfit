import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/friendship_repository_contract.dart';

/// Cancela una solicitud enviada, elimina una amistad o desbloquea.
abstract interface class RemoveFriendshipUseCaseContract {
  Future<AppResult<Unit>> call({required String friendshipId});
}

class RemoveFriendshipUseCase implements RemoveFriendshipUseCaseContract {
  const RemoveFriendshipUseCase(this._repository);

  final FriendshipRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({required String friendshipId}) =>
      _repository.remove(friendshipId);
}
