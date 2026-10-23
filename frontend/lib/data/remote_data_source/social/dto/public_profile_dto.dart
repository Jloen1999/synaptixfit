import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/friendship_relation.dart';
import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/social/public_profile.dart';

part 'public_profile_dto.freezed.dart';
part 'public_profile_dto.g.dart';

/// Perfil público de un usuario (`PublicProfileResponse`).
@freezed
abstract class PublicProfileDto with _$PublicProfileDto {
  const factory PublicProfileDto({
    required String id,
    @Default('') String fullName,
    String? avatarUrl,
    String? privacy,
    @Default(false) bool restricted,
    int? level,
    int? streak,
    int? postsCount,
    int? friendsCount,
    String? relation,
    String? friendshipId,
  }) = _PublicProfileDto;

  const PublicProfileDto._();

  factory PublicProfileDto.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileDtoFromJson(json);

  /// Si el perfil está restringido, las métricas no se exponen aunque lleguen.
  PublicProfile toDomain() => PublicProfile(
    id: id,
    fullName: fullName,
    avatarUrl: avatarUrl,
    privacy: Visibility.fromApi(privacy),
    restricted: restricted,
    level: level,
    streak: restricted ? null : streak,
    postsCount: restricted ? null : postsCount,
    friendsCount: restricted ? null : friendsCount,
    relation: FriendshipRelation.fromApi(relation),
    friendshipId: friendshipId,
  );
}
