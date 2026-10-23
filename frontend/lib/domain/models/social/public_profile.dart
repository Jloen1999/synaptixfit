import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/friendship_relation.dart';
import '../../enums/visibility.dart';

part 'public_profile.freezed.dart';

/// Perfil público de otro usuario. Si [restricted], las métricas no son visibles.
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
  }) = _PublicProfile;
}
