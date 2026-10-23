import '../enums/friendship_list_kind.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/social/friendship.dart';
import '../models/social/social_page.dart';

/// Amistades: solicitudes, aceptación, rechazo, bloqueo y listados.
abstract interface class FriendshipRepositoryContract {
  Future<AppResult<SocialPage<Friendship>>> getFriendships({
    required FriendshipListKind kind,
    int page = 0,
    int size = 20,
  });

  Future<AppResult<Friendship>> sendRequest(String userId);

  Future<AppResult<Friendship>> accept(String friendshipId);

  Future<AppResult<Friendship>> reject(String friendshipId);

  Future<AppResult<Friendship>> block(String userId);

  /// Cancela una solicitud enviada, elimina una amistad o desbloquea.
  Future<AppResult<Unit>> remove(String friendshipId);
}
