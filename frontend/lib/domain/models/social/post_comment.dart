import 'package:freezed_annotation/freezed_annotation.dart';

import 'social_user.dart';

part 'post_comment.freezed.dart';

/// Comentario de una publicación.
@freezed
abstract class PostComment with _$PostComment {
  const factory PostComment({
    required String id,
    required String postId,
    required SocialUser author,
    required String text,
    required DateTime createdAt,
    required bool edited,
    required bool mine,
  }) = _PostComment;
}
