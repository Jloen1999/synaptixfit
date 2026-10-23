import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/friendship_relation.dart';
import '../../../../domain/enums/friendship_status.dart';
import '../../../../domain/models/social/friendship.dart';
import 'social_user_dto.dart';

part 'friendship_dto.freezed.dart';
part 'friendship_dto.g.dart';

/// Amistad, solicitud o bloqueo (`FriendshipResponse`).
@freezed
abstract class FriendshipDto with _$FriendshipDto {
  const factory FriendshipDto({
    required String id,
    required String status,
    required String relation,
    required SocialUserDto user,
    required DateTime createdAt,
  }) = _FriendshipDto;

  const FriendshipDto._();

  factory FriendshipDto.fromJson(Map<String, dynamic> json) =>
      _$FriendshipDtoFromJson(json);

  Friendship toDomain() => Friendship(
    id: id,
    status: FriendshipStatus.fromApi(status),
    relation: FriendshipRelation.fromApi(relation),
    user: user.toDomain(),
    createdAt: createdAt.toLocal(),
  );
}
