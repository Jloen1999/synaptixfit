import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/friendship_relation.dart';
import '../../enums/friendship_status.dart';
import 'social_user.dart';

part 'friendship.freezed.dart';

/// Amistad, solicitud o bloqueo con otro usuario.
@freezed
abstract class Friendship with _$Friendship {
  const factory Friendship({
    required String id,
    required FriendshipStatus status,
    required FriendshipRelation relation,
    required SocialUser user,
    required DateTime createdAt,
  }) = _Friendship;
}
