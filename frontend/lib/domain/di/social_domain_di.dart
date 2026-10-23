import 'package:get_it/get_it.dart';

import '../use_cases/social/get_feed_use_case.dart';
import '../use_cases/social/get_post_use_case.dart';
import '../use_cases/social/create_post_use_case.dart';
import '../use_cases/social/edit_post_use_case.dart';
import '../use_cases/social/delete_post_use_case.dart';
import '../use_cases/social/report_post_use_case.dart';
import '../use_cases/social/set_post_like_use_case.dart';
import '../use_cases/social/get_comments_use_case.dart';
import '../use_cases/social/add_comment_use_case.dart';
import '../use_cases/social/edit_comment_use_case.dart';
import '../use_cases/social/delete_comment_use_case.dart';
import '../use_cases/social/report_comment_use_case.dart';
import '../use_cases/social/search_users_use_case.dart';
import '../use_cases/social/get_public_profile_use_case.dart';
import '../use_cases/social/get_friendships_use_case.dart';
import '../use_cases/social/send_friend_request_use_case.dart';
import '../use_cases/social/accept_friend_request_use_case.dart';
import '../use_cases/social/reject_friend_request_use_case.dart';
import '../use_cases/social/block_user_use_case.dart';
import '../use_cases/social/remove_friendship_use_case.dart';
import '../use_cases/notifications/get_notifications_use_case.dart';
import '../use_cases/notifications/get_unread_notifications_count_use_case.dart';
import '../use_cases/notifications/mark_notification_read_use_case.dart';
import '../use_cases/notifications/mark_all_notifications_read_use_case.dart';
import '../use_cases/notifications/delete_notification_use_case.dart';

/// Casos de uso del módulo social (muro, amistades y notificaciones).
void registerSocialDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<GetFeedUseCaseContract>(
      () => GetFeedUseCase(getIt()),
    )
    ..registerLazySingleton<GetPostUseCaseContract>(
      () => GetPostUseCase(getIt()),
    )
    ..registerLazySingleton<CreatePostUseCaseContract>(
      () => CreatePostUseCase(getIt()),
    )
    ..registerLazySingleton<EditPostUseCaseContract>(
      () => EditPostUseCase(getIt()),
    )
    ..registerLazySingleton<DeletePostUseCaseContract>(
      () => DeletePostUseCase(getIt()),
    )
    ..registerLazySingleton<ReportPostUseCaseContract>(
      () => ReportPostUseCase(getIt()),
    )
    ..registerLazySingleton<SetPostLikeUseCaseContract>(
      () => SetPostLikeUseCase(getIt()),
    )
    ..registerLazySingleton<GetCommentsUseCaseContract>(
      () => GetCommentsUseCase(getIt()),
    )
    ..registerLazySingleton<AddCommentUseCaseContract>(
      () => AddCommentUseCase(getIt()),
    )
    ..registerLazySingleton<EditCommentUseCaseContract>(
      () => EditCommentUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteCommentUseCaseContract>(
      () => DeleteCommentUseCase(getIt()),
    )
    ..registerLazySingleton<ReportCommentUseCaseContract>(
      () => ReportCommentUseCase(getIt()),
    )
    ..registerLazySingleton<SearchUsersUseCaseContract>(
      () => SearchUsersUseCase(getIt()),
    )
    ..registerLazySingleton<GetPublicProfileUseCaseContract>(
      () => GetPublicProfileUseCase(getIt()),
    )
    ..registerLazySingleton<GetFriendshipsUseCaseContract>(
      () => GetFriendshipsUseCase(getIt()),
    )
    ..registerLazySingleton<SendFriendRequestUseCaseContract>(
      () => SendFriendRequestUseCase(getIt()),
    )
    ..registerLazySingleton<AcceptFriendRequestUseCaseContract>(
      () => AcceptFriendRequestUseCase(getIt()),
    )
    ..registerLazySingleton<RejectFriendRequestUseCaseContract>(
      () => RejectFriendRequestUseCase(getIt()),
    )
    ..registerLazySingleton<BlockUserUseCaseContract>(
      () => BlockUserUseCase(getIt()),
    )
    ..registerLazySingleton<RemoveFriendshipUseCaseContract>(
      () => RemoveFriendshipUseCase(getIt()),
    )
    ..registerLazySingleton<GetNotificationsUseCaseContract>(
      () => GetNotificationsUseCase(getIt()),
    )
    ..registerLazySingleton<GetUnreadNotificationsCountUseCaseContract>(
      () => GetUnreadNotificationsCountUseCase(getIt()),
    )
    ..registerLazySingleton<MarkNotificationReadUseCaseContract>(
      () => MarkNotificationReadUseCase(getIt()),
    )
    ..registerLazySingleton<MarkAllNotificationsReadUseCaseContract>(
      () => MarkAllNotificationsReadUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteNotificationUseCaseContract>(
      () => DeleteNotificationUseCase(getIt()),
    );
}
