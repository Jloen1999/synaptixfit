part of 'post_detail_bloc.dart';

@freezed
abstract class PostDetailState with _$PostDetailState {
  const factory PostDetailState({
    @Default('') String postId,
    @Default(SocialLoadStatus.loading) SocialLoadStatus status,
    Post? post,
    @Default(false) bool submitting,

    /// La publicación se ha borrado: la página vuelve atrás.
    @Default(false) bool deleted,
    AppError? error,
    SocialFeedback? feedback,
  }) = _PostDetailState;
}
