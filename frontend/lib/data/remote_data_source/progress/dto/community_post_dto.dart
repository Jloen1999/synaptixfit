import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/community_post_kind.dart';
import '../../../../domain/models/progress/community_post_preview.dart';

part 'community_post_dto.freezed.dart';
part 'community_post_dto.g.dart';

/// Página de `PostResponse` (solo los campos que usa la vista previa).
@freezed
abstract class CommunityPostPageDto with _$CommunityPostPageDto {
  const factory CommunityPostPageDto({
    @Default(<CommunityPostDto>[]) List<CommunityPostDto> items,
  }) = _CommunityPostPageDto;

  factory CommunityPostPageDto.fromJson(Map<String, dynamic> json) =>
      _$CommunityPostPageDtoFromJson(json);
}

@freezed
abstract class CommunityPostDto with _$CommunityPostDto {
  const factory CommunityPostDto({
    required String id,
    CommunityAuthorDto? author,
    String? type,
    @Default('') String description,
    required DateTime createdAt,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
  }) = _CommunityPostDto;

  const CommunityPostDto._();

  factory CommunityPostDto.fromJson(Map<String, dynamic> json) =>
      _$CommunityPostDtoFromJson(json);

  CommunityPostPreview toDomain() => CommunityPostPreview(
    id: id,
    authorName: author?.fullName ?? '',
    authorAvatarUrl: author?.avatarUrl,
    kind: CommunityPostKind.fromApi(type),
    description: description,
    createdAt: createdAt.toLocal(),
    likesCount: likesCount,
    commentsCount: commentsCount,
  );
}

@freezed
abstract class CommunityAuthorDto with _$CommunityAuthorDto {
  const factory CommunityAuthorDto({
    required String id,
    @Default('') String fullName,
    String? avatarUrl,
  }) = _CommunityAuthorDto;

  factory CommunityAuthorDto.fromJson(Map<String, dynamic> json) =>
      _$CommunityAuthorDtoFromJson(json);
}
