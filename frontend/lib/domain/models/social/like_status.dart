import 'package:freezed_annotation/freezed_annotation.dart';

part 'like_status.freezed.dart';

/// Estado del «me gusta» de una publicación tras darlo o quitarlo.
@freezed
abstract class LikeStatus with _$LikeStatus {
  const factory LikeStatus({
    required String postId,
    required bool liked,
    required int likesCount,
  }) = _LikeStatus;
}
