import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/social/post_comment.dart';
import 'social_user_dto.dart';

part 'comment_dto.freezed.dart';
part 'comment_dto.g.dart';

/// Comentario de una publicación (`CommentResponse`).
@freezed
abstract class CommentDto with _$CommentDto {
  const factory CommentDto({
    required String id,
    required String postId,
    required SocialUserDto author,
    @Default('') String text,
    required DateTime createdAt,
    @Default(false) bool edited,
    @Default(false) bool mine,
  }) = _CommentDto;

  const CommentDto._();

  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);

  PostComment toDomain() => PostComment(
    id: id,
    postId: postId,
    author: author.toDomain(),
    text: text,
    createdAt: createdAt.toLocal(),
    edited: edited,
    mine: mine,
  );
}
