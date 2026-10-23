import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/community_post_kind.dart';

part 'community_post_preview.freezed.dart';

/// Resumen de una publicación del muro para la vista previa de Progreso.
@freezed
abstract class CommunityPostPreview with _$CommunityPostPreview {
  const factory CommunityPostPreview({
    required String id,
    required String authorName,
    String? authorAvatarUrl,
    required CommunityPostKind kind,
    required String description,
    required DateTime createdAt,
    required int likesCount,
    required int commentsCount,
  }) = _CommunityPostPreview;
}
