import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/friendship_relation.dart';
import '../../../../domain/models/social/user_card.dart';

part 'user_card_dto.freezed.dart';
part 'user_card_dto.g.dart';

/// Resultado de búsqueda de usuarios (`UserCardResponse`).
@freezed
abstract class UserCardDto with _$UserCardDto {
  const factory UserCardDto({
    required String id,
    @Default('') String fullName,
    String? avatarUrl,
    int? level,
    String? relation,
    String? friendshipId,
  }) = _UserCardDto;

  const UserCardDto._();

  factory UserCardDto.fromJson(Map<String, dynamic> json) =>
      _$UserCardDtoFromJson(json);

  UserCard toDomain() => UserCard(
    id: id,
    fullName: fullName,
    avatarUrl: avatarUrl,
    level: level,
    relation: FriendshipRelation.fromApi(relation),
    friendshipId: friendshipId,
  );
}
