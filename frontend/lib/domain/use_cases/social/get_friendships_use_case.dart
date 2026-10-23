import '../../enums/friendship_list_kind.dart';
import '../../models/result/app_result.dart';
import '../../models/social/friendship.dart';
import '../../models/social/social_page.dart';
import '../../repositories/friendship_repository_contract.dart';

/// Amigos, solicitudes recibidas/enviadas o bloqueados.
abstract interface class GetFriendshipsUseCaseContract {
  Future<AppResult<SocialPage<Friendship>>> call({
    required FriendshipListKind kind,
    int page = 0,
    int size = 20,
  });
}

class GetFriendshipsUseCase implements GetFriendshipsUseCaseContract {
  const GetFriendshipsUseCase(this._repository);

  final FriendshipRepositoryContract _repository;

  @override
  Future<AppResult<SocialPage<Friendship>>> call({
    required FriendshipListKind kind,
    int page = 0,
    int size = 20,
  }) => _repository.getFriendships(kind: kind, page: page, size: size);
}
