part of 'comments_bloc.dart';

@freezed
abstract class CommentsState with _$CommentsState {
  const factory CommentsState({
    @Default('') String postId,
    @Default(SocialLoadStatus.loading) SocialLoadStatus status,
    @Default(<PostComment>[]) List<PostComment> comments,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,
    @Default(false) bool sending,

    /// Total de comentarios de la publicación (según la API).
    @Default(0) int totalCount,

    /// Comentarios enviados con éxito (la página vacía el campo cuando cambia).
    @Default(0) int sentCount,
    AppError? error,
    SocialFeedback? feedback,
  }) = _CommentsState;
}
