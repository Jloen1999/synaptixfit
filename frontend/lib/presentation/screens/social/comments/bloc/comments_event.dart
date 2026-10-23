part of 'comments_bloc.dart';

@freezed
sealed class CommentsEvent with _$CommentsEvent {
  const factory CommentsEvent.started(String postId) = CommentsStarted;

  const factory CommentsEvent.nextPageRequested() = CommentsNextPageRequested;

  const factory CommentsEvent.submitted(String text) = CommentsSubmitted;

  const factory CommentsEvent.edited({
    required String commentId,
    required String text,
  }) = CommentsEdited;

  const factory CommentsEvent.deleted(String commentId) = CommentsDeleted;

  const factory CommentsEvent.reported(String commentId) = CommentsReported;
}
