import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/badge_rarity.dart';
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
    @Default(<PublicBadgeDto>[]) List<PublicBadgeDto> badges,
  }) = _PublicProfileDto;

  const PublicProfileDto._();

  factory PublicProfileDto.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileDtoFromJson(json);

  /// Si el perfil está restringido, las métricas y las insignias no se
  /// exponen aunque lleguen.
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
    badges: restricted ? const [] : [for (final b in badges) b.toDomain()],
  );
}

/// Insignia del perfil público (`PublicBadgeResponse`).
@freezed
abstract class PublicBadgeDto with _$PublicBadgeDto {
  const factory PublicBadgeDto({
    required String id,
    @Default('') String name,
    @Default('') String description,
    @Default('') String icon,
    String? rarity,
    DateTime? earnedAt,
  }) = _PublicBadgeDto;

  const PublicBadgeDto._();

  factory PublicBadgeDto.fromJson(Map<String, dynamic> json) =>
      _$PublicBadgeDtoFromJson(json);

  PublicBadge toDomain() => PublicBadge(
    id: id,
    name: name,
    description: description,
    icon: icon,
    rarity: BadgeRarity.fromApi(rarity),
    earnedAt: earnedAt?.toLocal(),
  );
}
