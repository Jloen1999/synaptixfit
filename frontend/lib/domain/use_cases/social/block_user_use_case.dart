import '../../models/result/app_result.dart';
import '../../models/social/friendship.dart';
import '../../repositories/friendship_repository_contract.dart';

/// Bloquea a un usuario.
abstract interface class BlockUserUseCaseContract {
  Future<AppResult<Friendship>> call({required String userId});
}

class BlockUserUseCase implements BlockUserUseCaseContract {
  const BlockUserUseCase(this._repository);

  final FriendshipRepositoryContract _repository;

  @override
  Future<AppResult<Friendship>> call({required String userId}) =>
      _repository.block(userId);
}
