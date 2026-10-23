part of 'post_detail_bloc.dart';

@freezed
sealed class PostDetailEvent with _$PostDetailEvent {
  const factory PostDetailEvent.started(String postId) = PostDetailStarted;

  const factory PostDetailEvent.likeToggled() = PostDetailLikeToggled;

  const factory PostDetailEvent.edited({
    required String description,
    String? imageUrl,
  }) = PostDetailEdited;

  const factory PostDetailEvent.deleted() = PostDetailDeleted;

  const factory PostDetailEvent.reported() = PostDetailReported;

  const factory PostDetailEvent.commentsCountChanged(int count) =
      PostDetailCommentsCountChanged;
}
