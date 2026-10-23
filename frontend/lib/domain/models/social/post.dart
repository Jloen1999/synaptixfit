import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/post_type.dart';
import 'post_link.dart';
import 'social_user.dart';

part 'post.freezed.dart';

/// Publicación del muro social.
@freezed
abstract class Post with _$Post {
  const factory Post({
    required String id,
    required SocialUser author,
    required PostType type,
    required String description,
    String? imageUrl,
    PostLink? link,
    required DateTime createdAt,
    required bool edited,
    required int likesCount,
    required int commentsCount,
    required bool likedByMe,
    required bool mine,
  }) = _Post;
}
