import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/feed_period.dart';
import '../../../../../domain/enums/post_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/social/post.dart';
import '../../../../../domain/use_cases/notifications/get_unread_notifications_count_use_case.dart';
import '../../../../../domain/use_cases/social/create_post_use_case.dart';
import '../../../../../domain/use_cases/social/delete_post_use_case.dart';
import '../../../../../domain/use_cases/social/edit_post_use_case.dart';
import '../../../../../domain/use_cases/social/get_feed_use_case.dart';
import '../../../../../domain/use_cases/social/get_post_use_case.dart';
import '../../../../../domain/use_cases/social/report_post_use_case.dart';
import '../../../../../domain/use_cases/social/set_post_like_use_case.dart';
import '../../widgets/social_feedback.dart';

part 'feed_bloc.freezed.dart';
part 'feed_event.dart';
part 'feed_state.dart';

/// Muro social: paginación, filtro temporal, sondeo de novedades (sustituye a
/// Supabase Realtime), «me gusta» optimista y gestión de publicaciones.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedBloc({
    required this._getFeed,
    required this._getPost,
    required this._createPost,
    required this._editPost,
    required this._deletePost,
    required this._reportPost,
    required this._setLike,
    required this._unreadCount,
    this.pollInterval = const Duration(seconds: 30),
    this.pageSize = 20,
  }) : super(const FeedState()) {
    on<FeedStarted>(_onStarted);
    on<FeedPeriodChanged>(_onPeriodChanged);
    on<FeedRefreshed>(_onRefreshed);
    on<FeedNextPageRequested>(_onNextPage);
    on<FeedPollingStarted>(_onPollingStarted);
    on<FeedPollingStopped>(_onPollingStopped);
    on<FeedPollTicked>(_onPollTicked);
    on<FeedNewPostsShown>(_onNewPostsShown);
    on<FeedLikeToggled>(_onLikeToggled);
    on<FeedPostSubmitted>(_onPostSubmitted);
    on<FeedPostEdited>(_onPostEdited);
    on<FeedPostDeleted>(_onPostDeleted);
    on<FeedPostReported>(_onPostReported);
    on<FeedPostRefreshRequested>(_onPostRefreshRequested);
    on<FeedCommentsCountChanged>(_onCommentsCountChanged);
  }

  final GetFeedUseCaseContract _getFeed;
  final GetPostUseCaseContract _getPost;
  final CreatePostUseCaseContract _createPost;
  final EditPostUseCaseContract _editPost;
  final DeletePostUseCaseContract _deletePost;
  final ReportPostUseCaseContract _reportPost;
  final SetPostLikeUseCaseContract _setLike;
  final GetUnreadNotificationsCountUseCaseContract _unreadCount;

  /// Cada cuánto se consultan publicaciones nuevas mientras el muro es visible.
  final Duration pollInterval;
  final int pageSize;

  Timer? _pollTimer;
  DateTime? _loadedAt;
  final _likesInFlight = <String>{};

  Future<void> _onStarted(FeedStarted event, Emitter<FeedState> emit) async {
    emit(FeedState(period: state.period));
    await Future.wait([_loadFirstPage(emit), _loadUnreadCount(emit)]);
  }

  Future<void> _onPeriodChanged(
    FeedPeriodChanged event,
    Emitter<FeedState> emit,
  ) async {
    if (event.period == state.period &&
        state.status != SocialLoadStatus.failure) {
      return;
    }
    emit(
      FeedState(
        period: event.period,
        unreadNotifications: state.unreadNotifications,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onRefreshed(
    FeedRefreshed event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.copyWith(refreshing: true));
    final period = state.period;
    final result = await _getFeed(period: period, size: pageSize);
    await _loadUnreadCount(emit);
    if (period != state.period) return;
    result.fold(
      (page) {
        _loadedAt = DateTime.now();
        emit(
          state.copyWith(
            refreshing: false,
            status: SocialLoadStatus.loaded,
            posts: page.items,
            newPosts: const [],
            page: page.page,
            hasMore: page.hasMore,
            error: null,
          ),
        );
      },
      (error) => state.status == SocialLoadStatus.loaded
          ? _notify(
              emit,
              state.copyWith(refreshing: false),
              SocialFeedback.error(error),
            )
          : emit(
              state.copyWith(
                refreshing: false,
                status: SocialLoadStatus.failure,
                error: error,
              ),
            ),
    );
  }

  Future<void> _onNextPage(
    FeedNextPageRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (!state.hasMore ||
        state.loadingMore ||
        state.status != SocialLoadStatus.loaded) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    final period = state.period;
    final result = await _getFeed(
      period: period,
      page: state.page + 1,
      size: pageSize,
    );
    if (period != state.period) return;
    result.fold(
      (page) {
        final known = _knownIds();
        emit(
          state.copyWith(
            loadingMore: false,
            posts: [
              ...state.posts,
              ...page.items.where((p) => !known.contains(p.id)),
            ],
            page: page.page,
            hasMore: page.hasMore,
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

  void _onPollingStarted(FeedPollingStarted event, Emitter<FeedState> emit) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      pollInterval,
      (_) => add(const FeedEvent.pollTicked()),
    );
  }

  void _onPollingStopped(FeedPollingStopped event, Emitter<FeedState> emit) {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Busca publicaciones creadas después de la más reciente conocida y las
  /// deja en [FeedState.newPosts] hasta que el usuario toque el aviso.
  Future<void> _onPollTicked(
    FeedPollTicked event,
    Emitter<FeedState> emit,
  ) async {
    if (state.status != SocialLoadStatus.loaded || state.refreshing) return;
    final since = _newestCreatedAt() ?? _loadedAt;
    final period = state.period;
    final result = await _getFeed(period: period, since: since, size: pageSize);
    await _loadUnreadCount(emit);
    if (period != state.period) return;
    final page = result.valueOrNull;
    if (page == null) return; // El sondeo falla en silencio.
    final known = _knownIds();
    final fresh = page.items.where((p) => !known.contains(p.id)).toList();
    if (fresh.isEmpty) return;
    emit(state.copyWith(newPosts: [...fresh, ...state.newPosts]));
  }

  void _onNewPostsShown(FeedNewPostsShown event, Emitter<FeedState> emit) {
    if (state.newPosts.isEmpty) return;
    emit(
      state.copyWith(posts: [...state.newPosts, ...state.posts], newPosts: []),
    );
  }

  Future<void> _onLikeToggled(
    FeedLikeToggled event,
    Emitter<FeedState> emit,
  ) async {
    final original = _find(event.postId);
    if (original == null || !_likesInFlight.add(event.postId)) return;
    final liked = !original.likedByMe;
    emit(
      _replacePost(
        original.copyWith(
          likedByMe: liked,
          likesCount: liked
              ? original.likesCount + 1
              : (original.likesCount > 0 ? original.likesCount - 1 : 0),
        ),
      ),
    );
    final result = await _setLike(postId: event.postId, liked: liked);
    _likesInFlight.remove(event.postId);
    final current = _find(event.postId);
    if (current == null) return;
    result.fold(
      (status) => emit(
        _replacePost(
          current.copyWith(
            likedByMe: status.liked,
            likesCount: status.likesCount,
          ),
        ),
      ),
      (error) => _notify(
        emit,
        _replacePost(
          current.copyWith(
            likedByMe: original.likedByMe,
            likesCount: original.likesCount,
          ),
        ),
        SocialFeedback.error(error),
      ),
    );
  }

  Future<void> _onPostSubmitted(
    FeedPostSubmitted event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.copyWith(submitting: true));
    final result = await _createPost(
      type: event.type,
      description: event.description,
      imageUrl: event.imageUrl,
    );
    result.fold(
      (post) => _notify(
        emit,
        state.copyWith(
          submitting: false,
          posts: [post, ...state.posts.where((p) => p.id != post.id)],
          status: SocialLoadStatus.loaded,
        ),
        const SocialFeedback.message(SocialMessage.postCreated),
      ),
      (error) => _notify(
        emit,
        state.copyWith(submitting: false),
        SocialFeedback.error(error),
      ),
    );
  }

  Future<void> _onPostEdited(
    FeedPostEdited event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.copyWith(submitting: true));
    final result = await _editPost(
      postId: event.postId,
      description: event.description,
      imageUrl: event.imageUrl,
    );
    result.fold(
      (post) => _notify(
        emit,
        _replacePost(post).copyWith(submitting: false),
        const SocialFeedback.message(SocialMessage.postUpdated),
      ),
      (error) => _notify(
        emit,
        state.copyWith(submitting: false),
        SocialFeedback.error(error),
      ),
    );
  }

  Future<void> _onPostDeleted(
    FeedPostDeleted event,
    Emitter<FeedState> emit,
  ) async {
    final result = await _deletePost(postId: event.postId);
    result.fold(
      (_) => _notify(
        emit,
        _removePost(event.postId),
        const SocialFeedback.message(SocialMessage.postDeleted),
      ),
      (error) => _notify(emit, state, SocialFeedback.error(error)),
    );
  }

  Future<void> _onPostReported(
    FeedPostReported event,
    Emitter<FeedState> emit,
  ) async {
    final result = await _reportPost(postId: event.postId);
    _notify(
      emit,
      state,
      result.fold(
        (_) => const SocialFeedback.message(SocialMessage.reported),
        SocialFeedback.error,
      ),
    );
  }

  /// Al volver del detalle: recarga la publicación o la quita si ya no existe.
  Future<void> _onPostRefreshRequested(
    FeedPostRefreshRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (_find(event.postId) == null) return;
    final result = await _getPost(postId: event.postId);
    result.fold((post) => emit(_replacePost(post)), (error) {
      if (error is NotFoundError ||
          error == const AppError.business('POST_NOT_FOUND')) {
        emit(_removePost(event.postId));
      }
    });
  }

  void _onCommentsCountChanged(
    FeedCommentsCountChanged event,
    Emitter<FeedState> emit,
  ) {
    final post = _find(event.postId);
    if (post == null || post.commentsCount == event.count) return;
    emit(_replacePost(post.copyWith(commentsCount: event.count)));
  }

  Future<void> _loadFirstPage(Emitter<FeedState> emit) async {
    final period = state.period;
    final result = await _getFeed(period: period, size: pageSize);
    if (period != state.period) return;
    result.fold(
      (page) {
        _loadedAt = DateTime.now();
        emit(
          state.copyWith(
            status: SocialLoadStatus.loaded,
            posts: page.items,
            newPosts: const [],
            page: page.page,
            hasMore: page.hasMore,
            error: null,
          ),
        );
      },
      (error) =>
          emit(state.copyWith(status: SocialLoadStatus.failure, error: error)),
    );
  }

  Future<void> _loadUnreadCount(Emitter<FeedState> emit) async {
    final result = await _unreadCount();
    final count = result.valueOrNull;
    if (count != null && !emit.isDone && count != state.unreadNotifications) {
      emit(state.copyWith(unreadNotifications: count));
    }
  }

  Set<String> _knownIds() => {
    for (final p in state.posts) p.id,
    for (final p in state.newPosts) p.id,
  };

  DateTime? _newestCreatedAt() {
    DateTime? newest;
    for (final p in [...state.newPosts, ...state.posts]) {
      if (newest == null || p.createdAt.isAfter(newest)) newest = p.createdAt;
    }
    return newest;
  }

  Post? _find(String postId) {
    for (final p in state.posts) {
      if (p.id == postId) return p;
    }
    return null;
  }

  FeedState _replacePost(Post post) => state.copyWith(
    posts: [for (final p in state.posts) p.id == post.id ? post : p],
  );

  FeedState _removePost(String postId) => state.copyWith(
    posts: state.posts.where((p) => p.id != postId).toList(),
    newPosts: state.newPosts.where((p) => p.id != postId).toList(),
  );

  /// Emite el aviso y lo limpia para que la página lo muestre una sola vez.
  void _notify(
    Emitter<FeedState> emit,
    FeedState next,
    SocialFeedback feedback,
  ) {
    emit(next.copyWith(feedback: feedback));
    emit(next.copyWith(feedback: null));
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
