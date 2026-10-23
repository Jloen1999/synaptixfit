import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/models/social/post.dart';
import '../../../../../domain/models/social/public_profile.dart';
import '../../../../../domain/use_cases/social/accept_friend_request_use_case.dart';
import '../../../../../domain/use_cases/social/block_user_use_case.dart';
import '../../../../../domain/use_cases/social/get_feed_use_case.dart';
import '../../../../../domain/use_cases/social/get_public_profile_use_case.dart';
import '../../../../../domain/use_cases/social/reject_friend_request_use_case.dart';
import '../../../../../domain/use_cases/social/remove_friendship_use_case.dart';
import '../../../../../domain/use_cases/social/send_friend_request_use_case.dart';
import '../../../../../domain/use_cases/social/set_post_like_use_case.dart';
import '../../widgets/social_feedback.dart';

part 'user_profile_bloc.freezed.dart';
part 'user_profile_event.dart';
part 'user_profile_state.dart';

/// Acciones de relación disponibles desde el perfil público.
enum ProfileRelationAction {
  sendRequest,
  cancelRequest,
  accept,
  reject,
  removeFriend,
  block,
  unblock,
}

/// Perfil público de otro usuario, sus publicaciones y la relación conmigo.
class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  UserProfileBloc({
    required this._getProfile,
    required this._getFeed,
    required this._setLike,
    required this._sendRequest,
    required this._acceptRequest,
    required this._rejectRequest,
    required this._removeFriendship,
    required this._blockUser,
    this.pageSize = 20,
  }) : super(const UserProfileState()) {
    on<UserProfileStarted>(_onStarted);
    on<UserProfileRefreshed>(_onRefreshed);
    on<UserProfileNextPostsRequested>(_onNextPosts);
    on<UserProfileLikeToggled>(_onLikeToggled);
    on<UserProfileRelationActionRequested>(_onRelationAction);
  }

  final GetPublicProfileUseCaseContract _getProfile;
  final GetFeedUseCaseContract _getFeed;
  final SetPostLikeUseCaseContract _setLike;
  final SendFriendRequestUseCaseContract _sendRequest;
  final AcceptFriendRequestUseCaseContract _acceptRequest;
  final RejectFriendRequestUseCaseContract _rejectRequest;
  final RemoveFriendshipUseCaseContract _removeFriendship;
  final BlockUserUseCaseContract _blockUser;
  final int pageSize;
  final _likesInFlight = <String>{};

  Future<void> _onStarted(
    UserProfileStarted event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(UserProfileState(userId: event.userId));
    await _load(emit);
  }

  Future<void> _onRefreshed(
    UserProfileRefreshed event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(state.copyWith(refreshing: true));
    await _load(emit);
    emit(state.copyWith(refreshing: false));
  }

  Future<void> _load(Emitter<UserProfileState> emit) async {
    final (profile, posts) = await (
      _getProfile(userId: state.userId),
      _getFeed(authorId: state.userId, size: pageSize),
    ).wait;
    profile.fold(
      (value) {
        final page = posts.valueOrNull;
        emit(
          state.copyWith(
            status: SocialLoadStatus.loaded,
            profile: value,
            posts: page?.items ?? state.posts,
            postsPage: page?.page ?? 0,
            hasMorePosts: page?.hasMore ?? false,
            postsError: posts.errorOrNull,
            error: null,
          ),
        );
      },
      (error) =>
          emit(state.copyWith(status: SocialLoadStatus.failure, error: error)),
    );
  }

  Future<void> _onNextPosts(
    UserProfileNextPostsRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    if (!state.hasMorePosts || state.loadingMorePosts) return;
    emit(state.copyWith(loadingMorePosts: true));
    final result = await _getFeed(
      authorId: state.userId,
      page: state.postsPage + 1,
      size: pageSize,
    );
    result.fold(
      (page) {
        final known = state.posts.map((p) => p.id).toSet();
        emit(
          state.copyWith(
            loadingMorePosts: false,
            posts: [
              ...state.posts,
              ...page.items.where((p) => !known.contains(p.id)),
            ],
            postsPage: page.page,
            hasMorePosts: page.hasMore,
          ),
        );
      },
      (error) => _notify(
        emit,
        state.copyWith(loadingMorePosts: false),
        SocialFeedback.error(error),
      ),
    );
  }

  Future<void> _onLikeToggled(
    UserProfileLikeToggled event,
    Emitter<UserProfileState> emit,
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
    final current = _find(event.postId) ?? original;
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

  /// Ejecuta la acción y recarga el perfil y sus publicaciones (la relación
  /// cambia lo que se puede ver).
  Future<void> _onRelationAction(
    UserProfileRelationActionRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    final profile = state.profile;
    if (profile == null || state.busy) return;
    final friendshipId = profile.friendshipId;
    emit(state.copyWith(busy: true));
    final AppResult<Object?> result = switch (event.action) {
      ProfileRelationAction.sendRequest => await _sendRequest(
        userId: profile.id,
      ),
      ProfileRelationAction.block => await _blockUser(userId: profile.id),
      ProfileRelationAction.accept when friendshipId != null =>
        await _acceptRequest(friendshipId: friendshipId),
      ProfileRelationAction.reject when friendshipId != null =>
        await _rejectRequest(friendshipId: friendshipId),
      ProfileRelationAction.cancelRequest ||
      ProfileRelationAction.removeFriend ||
      ProfileRelationAction.unblock when friendshipId != null =>
        await _removeFriendship(friendshipId: friendshipId),
      _ => const AppResult<Object?>.failure(
        AppError.business('FRIENDSHIP_NOT_FOUND'),
      ),
    };
    final error = result.errorOrNull;
    if (error != null) {
      _notify(emit, state.copyWith(busy: false), SocialFeedback.error(error));
      return;
    }
    await _load(emit);
    _notify(
      emit,
      state.copyWith(busy: false),
      SocialFeedback.message(switch (event.action) {
        ProfileRelationAction.sendRequest => SocialMessage.requestSent,
        ProfileRelationAction.cancelRequest => SocialMessage.requestCancelled,
        ProfileRelationAction.accept => SocialMessage.requestAccepted,
        ProfileRelationAction.reject => SocialMessage.requestRejected,
        ProfileRelationAction.removeFriend => SocialMessage.friendRemoved,
        ProfileRelationAction.block => SocialMessage.userBlocked,
        ProfileRelationAction.unblock => SocialMessage.userUnblocked,
      }),
    );
  }

  Post? _find(String postId) {
    for (final p in state.posts) {
      if (p.id == postId) return p;
    }
    return null;
  }

  UserProfileState _replacePost(Post post) => state.copyWith(
    posts: [for (final p in state.posts) p.id == post.id ? post : p],
  );

  void _notify(
    Emitter<UserProfileState> emit,
    UserProfileState next,
    SocialFeedback feedback,
  ) {
    emit(next.copyWith(feedback: feedback));
    emit(next.copyWith(feedback: null));
  }
}
