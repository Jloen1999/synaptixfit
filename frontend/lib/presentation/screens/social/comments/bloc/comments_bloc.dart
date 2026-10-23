import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/social/post_comment.dart';
import '../../../../../domain/use_cases/social/add_comment_use_case.dart';
import '../../../../../domain/use_cases/social/delete_comment_use_case.dart';
import '../../../../../domain/use_cases/social/edit_comment_use_case.dart';
import '../../../../../domain/use_cases/social/get_comments_use_case.dart';
import '../../../../../domain/use_cases/social/report_comment_use_case.dart';
import '../../widgets/social_feedback.dart';

part 'comments_bloc.freezed.dart';
part 'comments_event.dart';
part 'comments_state.dart';

/// Comentarios de una publicación: se usa en la tarjeta del muro (expandible)
/// y en el detalle de la publicación.
class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  CommentsBloc({
    required this._getComments,
    required this._addComment,
    required this._editComment,
    required this._deleteComment,
    required this._reportComment,
    this.pageSize = 20,
  }) : super(const CommentsState()) {
    on<CommentsStarted>(_onStarted);
    on<CommentsNextPageRequested>(_onNextPage);
    on<CommentsSubmitted>(_onSubmitted);
    on<CommentsEdited>(_onEdited);
    on<CommentsDeleted>(_onDeleted);
    on<CommentsReported>(_onReported);
  }

  final GetCommentsUseCaseContract _getComments;
  final AddCommentUseCaseContract _addComment;
  final EditCommentUseCaseContract _editComment;
  final DeleteCommentUseCaseContract _deleteComment;
  final ReportCommentUseCaseContract _reportComment;
  final int pageSize;

  Future<void> _onStarted(
    CommentsStarted event,
    Emitter<CommentsState> emit,
  ) async {
    emit(CommentsState(postId: event.postId));
    final result = await _getComments(postId: event.postId, size: pageSize);
    emit(
      result.fold(
        (page) => state.copyWith(
          status: SocialLoadStatus.loaded,
          comments: page.items,
          page: page.page,
          hasMore: page.hasMore,
          totalCount: page.totalItems,
        ),
        (error) =>
            state.copyWith(status: SocialLoadStatus.failure, error: error),
      ),
    );
  }

  Future<void> _onNextPage(
    CommentsNextPageRequested event,
    Emitter<CommentsState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    final result = await _getComments(
      postId: state.postId,
      page: state.page + 1,
      size: pageSize,
    );
    result.fold(
      (page) {
        final known = state.comments.map((c) => c.id).toSet();
        emit(
          state.copyWith(
            loadingMore: false,
            comments: [
              ...state.comments,
              ...page.items.where((c) => !known.contains(c.id)),
            ],
            page: page.page,
            hasMore: page.hasMore,
            totalCount: page.totalItems,
          ),
        );
      },
      (error) => _notify(
        emit,
        state.copyWith(loadingMore: false),
        SocialFeedback.error(error),
      ),
    );
  }

  Future<void> _onSubmitted(
    CommentsSubmitted event,
    Emitter<CommentsState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || state.sending) return;
    emit(state.copyWith(sending: true));
    final result = await _addComment(postId: state.postId, text: text);
    result.fold(
      (comment) => emit(
        state.copyWith(
          sending: false,
          // Orden cronológico: el nuevo va al final si ya está todo cargado.
          comments: state.hasMore
              ? state.comments
              : [...state.comments, comment],
          totalCount: state.totalCount + 1,
          sentCount: state.sentCount + 1,
        ),
      ),
      (error) => _notify(
        emit,
        state.copyWith(sending: false),
        SocialFeedback.error(error),
      ),
    );
  }

  Future<void> _onEdited(
    CommentsEdited event,
    Emitter<CommentsState> emit,
  ) async {
    final result = await _editComment(
      commentId: event.commentId,
      text: event.text.trim(),
    );
    result.fold(
      (updated) => _notify(
        emit,
        state.copyWith(
          comments: [
            for (final c in state.comments) c.id == updated.id ? updated : c,
          ],
        ),
        const SocialFeedback.message(SocialMessage.commentUpdated),
      ),
      (error) => _notify(emit, state, SocialFeedback.error(error)),
    );
  }

  Future<void> _onDeleted(
    CommentsDeleted event,
    Emitter<CommentsState> emit,
  ) async {
    final result = await _deleteComment(commentId: event.commentId);
    result.fold(
      (_) => _notify(
        emit,
        state.copyWith(
          comments: state.comments
              .where((c) => c.id != event.commentId)
              .toList(),
          totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
        ),
        const SocialFeedback.message(SocialMessage.commentDeleted),
      ),
      (error) => _notify(emit, state, SocialFeedback.error(error)),
    );
  }

  Future<void> _onReported(
    CommentsReported event,
    Emitter<CommentsState> emit,
  ) async {
    final result = await _reportComment(commentId: event.commentId);
    _notify(
      emit,
      state,
      result.fold(
        (_) => const SocialFeedback.message(SocialMessage.reported),
        SocialFeedback.error,
      ),
    );
  }

  /// Emite el aviso y lo limpia para que la página lo muestre una sola vez.
  void _notify(
    Emitter<CommentsState> emit,
    CommentsState next,
    SocialFeedback feedback,
  ) {
    emit(next.copyWith(feedback: feedback));
    emit(next.copyWith(feedback: null));
  }
}
