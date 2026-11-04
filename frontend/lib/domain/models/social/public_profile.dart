import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/badge_rarity.dart';
import '../../enums/friendship_relation.dart';
import '../../enums/visibility.dart';

part 'public_profile.freezed.dart';

/// Perfil público de otro usuario. Si [restricted], las métricas y las
/// insignias no son visibles.
@freezed
abstract class PublicProfile with _$PublicProfile {
  const factory PublicProfile({
    required String id,
    required String fullName,
    String? avatarUrl,
    required Visibility privacy,
    required bool restricted,
    int? level,
    int? streak,
    int? postsCount,
    int? friendsCount,
    required FriendshipRelation relation,
    String? friendshipId,

    /// Insignias que la persona enseña, de la más rara a la más común (el
    /// orden lo decide el servidor).
    @Default(<PublicBadge>[]) List<PublicBadge> badges,
  }) = _PublicProfile;
}

/// Insignia ganada que alguien deja ver en su perfil.
@freezed
abstract class PublicBadge with _$PublicBadge {
  const factory PublicBadge({
    required String id,
    required String name,
    required String description,

    /// Emoji que representa la insignia.
    required String icon,
    required BadgeRarity rarity,
    DateTime? earnedAt,
  }) = _PublicBadge;
}
