import 'package:get_it/get_it.dart';

import '../screens/social/comments/bloc/comments_bloc.dart';
import '../screens/social/feed/bloc/feed_bloc.dart';
import '../screens/social/friends/bloc/friends_bloc.dart';
import '../screens/social/notifications/bloc/notifications_bloc.dart';
import '../screens/social/post_detail/bloc/post_detail_bloc.dart';
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
    );
}
