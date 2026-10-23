part of 'feed_bloc.dart';

@freezed
sealed class FeedEvent with _$FeedEvent {
  const factory FeedEvent.started() = FeedStarted;

  const factory FeedEvent.periodChanged(FeedPeriod period) = FeedPeriodChanged;

  const factory FeedEvent.refreshed() = FeedRefreshed;

  const factory FeedEvent.nextPageRequested() = FeedNextPageRequested;

  /// La pantalla es visible: empieza el sondeo periódico.
  const factory FeedEvent.pollingStarted() = FeedPollingStarted;

  /// La pantalla deja de verse (otra ruta encima o app en segundo plano).
  const factory FeedEvent.pollingStopped() = FeedPollingStopped;

  const factory FeedEvent.pollTicked() = FeedPollTicked;

  /// El usuario toca «Hay publicaciones nuevas».
  const factory FeedEvent.newPostsShown() = FeedNewPostsShown;

  const factory FeedEvent.likeToggled(String postId) = FeedLikeToggled;

  const factory FeedEvent.postSubmitted({
    required PostType type,
    required String description,
    String? imageUrl,
  }) = FeedPostSubmitted;

  const factory FeedEvent.postEdited({
    required String postId,
    required String description,
    String? imageUrl,
  }) = FeedPostEdited;

  const factory FeedEvent.postDeleted(String postId) = FeedPostDeleted;

  const factory FeedEvent.postReported(String postId) = FeedPostReported;

  const factory FeedEvent.postRefreshRequested(String postId) =
      FeedPostRefreshRequested;

  const factory FeedEvent.commentsCountChanged({
    required String postId,
    required int count,
  }) = FeedCommentsCountChanged;
}
