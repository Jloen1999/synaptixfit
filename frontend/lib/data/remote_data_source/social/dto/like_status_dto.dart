import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/social/like_status.dart';

part 'like_status_dto.freezed.dart';
part 'like_status_dto.g.dart';

/// Resultado de dar o quitar «me gusta» (`LikeStatusResponse`).
@freezed
abstract class LikeStatusDto with _$LikeStatusDto {
  const factory LikeStatusDto({
    required String postId,
    required bool liked,
    @Default(0) int likesCount,
  }) = _LikeStatusDto;

  const LikeStatusDto._();

  factory LikeStatusDto.fromJson(Map<String, dynamic> json) =>
      _$LikeStatusDtoFromJson(json);

  LikeStatus toDomain() =>
      LikeStatus(postId: postId, liked: liked, likesCount: likesCount);
}
