part of 'feed_bloc.dart';

@freezed
abstract class FeedState with _$FeedState {
  const factory FeedState({
    @Default(SocialLoadStatus.loading) SocialLoadStatus status,
    @Default(FeedPeriod.all) FeedPeriod period,
    @Default(<Post>[]) List<Post> posts,

    /// Publicaciones detectadas por el sondeo, pendientes de mostrar.
    @Default(<Post>[]) List<Post> newPosts,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,
    @Default(false) bool refreshing,

    /// Creando o editando una publicación.
    @Default(false) bool submitting,
    @Default(0) int unreadNotifications,
    AppError? error,
    SocialFeedback? feedback,
  }) = _FeedState;
}
