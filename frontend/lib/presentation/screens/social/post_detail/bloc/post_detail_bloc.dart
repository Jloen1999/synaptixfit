import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/social/post.dart';
import '../../../../../domain/use_cases/social/delete_post_use_case.dart';
import '../../../../../domain/use_cases/social/edit_post_use_case.dart';
import '../../../../../domain/use_cases/social/get_post_use_case.dart';
import '../../../../../domain/use_cases/social/report_post_use_case.dart';
import '../../../../../domain/use_cases/social/set_post_like_use_case.dart';
import '../../widgets/social_feedback.dart';

part 'post_detail_bloc.freezed.dart';
part 'post_detail_event.dart';
part 'post_detail_state.dart';

/// Detalle de una publicación (los comentarios los gestiona `CommentsBloc`).
class PostDetailBloc extends Bloc<PostDetailEvent, PostDetailState> {
  PostDetailBloc({
    required this._getPost,
    required this._editPost,
    required this._deletePost,
    required this._reportPost,
    required this._setLike,
  }) : super(const PostDetailState()) {
    on<PostDetailStarted>(_onStarted);
    on<PostDetailLikeToggled>(_onLikeToggled);
    on<PostDetailEdited>(_onEdited);
    on<PostDetailDeleted>(_onDeleted);
    on<PostDetailReported>(_onReported);
    on<PostDetailCommentsCountChanged>(_onCommentsCountChanged);
  }

  final GetPostUseCaseContract _getPost;
  final EditPostUseCaseContract _editPost;
  final DeletePostUseCaseContract _deletePost;
  final ReportPostUseCaseContract _reportPost;
  final SetPostLikeUseCaseContract _setLike;
  bool _likeInFlight = false;

  Future<void> _onStarted(
    PostDetailStarted event,
    Emitter<PostDetailState> emit,
  ) async {
    emit(PostDetailState(postId: event.postId));
    final result = await _getPost(postId: event.postId);
    emit(
      result.fold(
        (post) => state.copyWith(status: SocialLoadStatus.loaded, post: post),
        (error) =>
            state.copyWith(status: SocialLoadStatus.failure, error: error),
      ),
    );
  }

  Future<void> _onLikeToggled(
    PostDetailLikeToggled event,
    Emitter<PostDetailState> emit,
  ) async {
    final original = state.post;
    if (original == null || _likeInFlight) return;
    _likeInFlight = true;
    final liked = !original.likedByMe;
    emit(
      state.copyWith(
        post: original.copyWith(
          likedByMe: liked,
          likesCount: liked
              ? original.likesCount + 1
              : (original.likesCount > 0 ? original.likesCount - 1 : 0),
        ),
      ),
    );
    final result = await _setLike(postId: original.id, liked: liked);
    _likeInFlight = false;
    final current = state.post ?? original;
    result.fold(
      (status) => emit(
        state.copyWith(
          post: current.copyWith(
            likedByMe: status.liked,
            likesCount: status.likesCount,
          ),
        ),
      ),
      (error) => _notify(
        emit,
        state.copyWith(
          post: current.copyWith(
            likedByMe: original.likedByMe,
            likesCount: original.likesCount,
          ),
        ),
        SocialFeedback.error(error),
      ),
    );
  }

  Future<void> _onEdited(
    PostDetailEdited event,
    Emitter<PostDetailState> emit,
  ) async {
    emit(state.copyWith(submitting: true));
    final result = await _editPost(
      postId: state.postId,
      description: event.description,
      imageUrl: event.imageUrl,
    );
    result.fold(
      (post) => _notify(
        emit,
        state.copyWith(submitting: false, post: post),
        const SocialFeedback.message(SocialMessage.postUpdated),
      ),
      (error) => _notify(
        emit,
        state.copyWith(submitting: false),
        SocialFeedback.error(error),
      ),
    );
  }

  Future<void> _onDeleted(
    PostDetailDeleted event,
    Emitter<PostDetailState> emit,
  ) async {
    final result = await _deletePost(postId: state.postId);
    result.fold(
      (_) => _notify(
        emit,
        state.copyWith(deleted: true),
        const SocialFeedback.message(SocialMessage.postDeleted),
      ),
      (error) => _notify(emit, state, SocialFeedback.error(error)),
    );
  }

  Future<void> _onReported(
    PostDetailReported event,
    Emitter<PostDetailState> emit,
  ) async {
    final result = await _reportPost(postId: state.postId);
    _notify(
      emit,
      state,
      result.fold(
        (_) => const SocialFeedback.message(SocialMessage.reported),
        SocialFeedback.error,
      ),
    );
  }

  void _onCommentsCountChanged(
    PostDetailCommentsCountChanged event,
    Emitter<PostDetailState> emit,
  ) {
    final post = state.post;
    if (post == null || post.commentsCount == event.count) return;
    emit(state.copyWith(post: post.copyWith(commentsCount: event.count)));
  }

  void _notify(
    Emitter<PostDetailState> emit,
    PostDetailState next,
    SocialFeedback feedback,
  ) {
    emit(next.copyWith(feedback: feedback));
    emit(next.copyWith(feedback: null));
  }
}
