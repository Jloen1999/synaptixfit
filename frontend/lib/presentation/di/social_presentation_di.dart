import 'package:get_it/get_it.dart';

import '../screens/social/comments/bloc/comments_bloc.dart';
import '../screens/social/feed/bloc/feed_bloc.dart';
import '../screens/social/friends/bloc/friends_bloc.dart';
import '../screens/social/notifications/bloc/notifications_bloc.dart';
import '../screens/social/post_detail/bloc/post_detail_bloc.dart';
import '../screens/social/together/challenge_detail/bloc/friend_challenge_detail_bloc.dart';
import '../screens/social/together/challenge_form/bloc/friend_challenge_form_bloc.dart';
import '../screens/social/together/friend_picker/bloc/friend_picker_bloc.dart';
import '../screens/social/together/hub/bloc/together_bloc.dart';
import '../screens/social/together/live/bloc/workout_together_live_bloc.dart';
import '../screens/social/together/safety/bloc/together_safety_bloc.dart';
import '../screens/social/together/workout_detail/bloc/workout_together_bloc.dart';
import '../screens/social/together/workout_invite/bloc/workout_invite_bloc.dart';
import '../screens/social/user_profile/bloc/user_profile_bloc.dart';

/// Blocs del módulo social.
void registerSocialPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => FeedBloc(
        getFeed: getIt(),
        getPost: getIt(),
        createPost: getIt(),
        editPost: getIt(),
        deletePost: getIt(),
        reportPost: getIt(),
        setLike: getIt(),
        unreadCount: getIt(),
      ),
    )
    ..registerFactory(
      () => PostDetailBloc(
        getPost: getIt(),
        editPost: getIt(),
        deletePost: getIt(),
        reportPost: getIt(),
        setLike: getIt(),
      ),
    )
    ..registerFactory(
      () => CommentsBloc(
        getComments: getIt(),
        addComment: getIt(),
        editComment: getIt(),
        deleteComment: getIt(),
        reportComment: getIt(),
      ),
    )
    ..registerFactory(
      () => FriendsBloc(
        getFriendships: getIt(),
        searchUsers: getIt(),
        sendRequest: getIt(),
        acceptRequest: getIt(),
        rejectRequest: getIt(),
        removeFriendship: getIt(),
      ),
    )
    ..registerFactory(
      () => UserProfileBloc(
        getProfile: getIt(),
        getFeed: getIt(),
        setLike: getIt(),
        sendRequest: getIt(),
        acceptRequest: getIt(),
        rejectRequest: getIt(),
        removeFriendship: getIt(),
        blockUser: getIt(),
        getSharedNotes: getIt(),
      ),
    )
    ..registerFactory(
      () => NotificationsBloc(
        getNotifications: getIt(),
        markRead: getIt(),
        markAllRead: getIt(),
        deleteNotification: getIt(),
      ),
    )
    // Con amigos (ADR 0044).
    ..registerFactory(
      () => TogetherBloc(
        overview: getIt(),
        joinChallenge: getIt(),
        declineChallenge: getIt(),
        proposeStreak: getIt(),
        acceptStreak: getIt(),
        declineStreak: getIt(),
        endStreak: getIt(),
        nudgeStreak: getIt(),
        joinWorkout: getIt(),
        declineWorkout: getIt(),
      ),
    )
    ..registerFactory(() => TogetherSafetyBloc(block: getIt(), report: getIt()))
    ..registerFactory(() => FriendPickerBloc(friendships: getIt()))
    ..registerFactory(
      () => FriendChallengeFormBloc(templates: getIt(), create: getIt()),
    )
    ..registerFactory(
      () => FriendChallengeDetailBloc(
        get: getIt(),
        join: getIt(),
        decline: getIt(),
        leave: getIt(),
        react: getIt(),
        removeReaction: getIt(),
      ),
    )
    ..registerFactory(() => WorkoutInviteBloc(create: getIt()))
    ..registerFactory(
      () => WorkoutTogetherBloc(
        get: getIt(),
        join: getIt(),
        decline: getIt(),
        leave: getIt(),
        start: getIt(),
      ),
    )
    ..registerFactory(() => WorkoutTogetherLiveBloc(find: getIt()));
}
