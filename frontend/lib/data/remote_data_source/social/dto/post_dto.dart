import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/post_type.dart';
import '../../../../domain/models/social/post.dart';
import '../../../../domain/models/social/post_link.dart';
import 'social_user_dto.dart';

part 'post_dto.freezed.dart';
part 'post_dto.g.dart';

/// Publicación del muro (`PostResponse`).
@freezed
abstract class PostDto with _$PostDto {
  const factory PostDto({
    required String id,
    required SocialUserDto author,
    required String type,
    @Default('') String description,
    String? imageUrl,
    Object? metadata,
    required DateTime createdAt,
    @Default(false) bool edited,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
    @Default(false) bool likedByMe,
    @Default(false) bool mine,
  }) = _PostDto;

  const PostDto._();

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);

  Post toDomain() => Post(
    id: id,
    author: author.toDomain(),
    type: PostType.fromApi(type),
    description: description,
    imageUrl: imageUrl == null || imageUrl!.trim().isEmpty ? null : imageUrl,
    link: parsePostLink(metadata),
    createdAt: createdAt.toLocal(),
    edited: edited,
    likesCount: likesCount,
    commentsCount: commentsCount,
    likedByMe: likedByMe,
    mine: mine,
  );
}

/// Lee el enlace a rutina/reto/insignia de los metadatos libres de una
/// publicación. Acepta las claves nuevas (`entityType`, `entityId`,
/// `entityName`) y las heredadas de la app antigua (`entidad_tipo`…).
PostLink? parsePostLink(Object? metadata) {
  if (metadata is! Map) return null;
  String? read(List<String> keys) {
    for (final key in keys) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  final kind = switch (read([
    'entityType',
    'entity_type',
    'entidad_tipo',
  ])?.toLowerCase()) {
    'routine' || 'rutina' => PostLinkKind.routine,
    'challenge' || 'reto' => PostLinkKind.challenge,
    'badge' || 'insignia' => PostLinkKind.badge,
    _ => null,
  };
  final name = read(['entityName', 'entity_name', 'entidad_nombre']);
  if (kind == null || name == null) return null;
  return PostLink(
    kind: kind,
    id: read(['entityId', 'entity_id', 'entidad_id']),
    name: name,
  );
}
