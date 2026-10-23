import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/friendship_relation.dart';

part 'user_card.freezed.dart';

/// Resultado de búsqueda de usuarios con su relación conmigo.
@freezed
abstract class UserCard with _$UserCard {
  const factory UserCard({
    required String id,
    required String fullName,
    String? avatarUrl,
    int? level,
    required FriendshipRelation relation,
    String? friendshipId,
  }) = _UserCard;
}
