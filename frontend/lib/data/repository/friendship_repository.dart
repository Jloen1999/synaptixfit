import '../../domain/enums/friendship_list_kind.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/models/social/friendship.dart';
import '../../domain/models/social/social_page.dart';
import '../../domain/repositories/friendship_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/social/social_remote_data_source.dart';

class FriendshipRepository implements FriendshipRepositoryContract {
  FriendshipRepository(this._remote);

  final SocialRemoteDataSource _remote;

  @override
  Future<AppResult<SocialPage<Friendship>>> getFriendships({
    required FriendshipListKind kind,
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.friendships(
      kind: kind.apiValue,
      page: page,
      size: size,
    )).toDomain((dto) => dto.toDomain()),
  );

  @override
  Future<AppResult<Friendship>> sendRequest(String userId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.sendRequest(userId)).toDomain(),
      );

  @override
  Future<AppResult<Friendship>> accept(String friendshipId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.accept(friendshipId)).toDomain(),
      );

  @override
  Future<AppResult<Friendship>> reject(String friendshipId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.reject(friendshipId)).toDomain(),
      );

  @override
  Future<AppResult<Friendship>> block(String userId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.block(userId)).toDomain(),
      );

  @override
  Future<AppResult<Unit>> remove(String friendshipId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.removeFriendship(friendshipId);
        return unit;
      });
}
