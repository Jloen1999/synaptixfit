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
import '../use_cases/social/together/get_together_overview_use_case.dart';
import '../use_cases/social/together/get_friend_challenge_templates_use_case.dart';
import '../use_cases/social/together/create_friend_challenge_use_case.dart';
import '../use_cases/social/together/get_friend_challenge_use_case.dart';
import '../use_cases/social/together/join_friend_challenge_use_case.dart';
import '../use_cases/social/together/decline_friend_challenge_use_case.dart';
import '../use_cases/social/together/leave_friend_challenge_use_case.dart';
import '../use_cases/social/together/react_to_friend_challenge_use_case.dart';
import '../use_cases/social/together/remove_friend_challenge_reaction_use_case.dart';
import '../use_cases/social/together/propose_friend_streak_use_case.dart';
import '../use_cases/social/together/accept_friend_streak_use_case.dart';
import '../use_cases/social/together/decline_friend_streak_use_case.dart';
import '../use_cases/social/together/end_friend_streak_use_case.dart';
import '../use_cases/social/together/nudge_friend_streak_use_case.dart';
import '../use_cases/social/together/create_workout_together_use_case.dart';
import '../use_cases/social/together/get_workout_together_use_case.dart';
import '../use_cases/social/together/find_workout_together_by_session_use_case.dart';
import '../use_cases/social/together/join_workout_together_use_case.dart';
import '../use_cases/social/together/decline_workout_together_use_case.dart';
import '../use_cases/social/together/leave_workout_together_use_case.dart';
import '../use_cases/social/together/start_workout_together_use_case.dart';
import '../use_cases/social/together/report_user_use_case.dart';
import '../use_cases/social/together/get_together_limits_use_case.dart';
import '../use_cases/social/together/create_study_room_use_case.dart';
import '../use_cases/social/together/get_study_room_use_case.dart';
import '../use_cases/social/together/join_study_room_use_case.dart';
import '../use_cases/social/together/decline_study_room_use_case.dart';
import '../use_cases/social/together/leave_study_room_use_case.dart';
import '../use_cases/social/together/start_study_room_use_case.dart';
import '../use_cases/social/together/choose_study_room_subject_use_case.dart';
import '../use_cases/social/together/react_in_study_room_use_case.dart';
import '../use_cases/notifications/get_notifications_use_case.dart';
import '../use_cases/notifications/get_unread_notifications_count_use_case.dart';
import '../use_cases/notifications/mark_notification_read_use_case.dart';
import '../use_cases/notifications/mark_all_notifications_read_use_case.dart';
import '../use_cases/notifications/delete_notification_use_case.dart';

/// Casos de uso del módulo social (muro, amistades, notificaciones y «Con
/// amigos», ADR 0044).
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
    )
    ..registerLazySingleton<GetTogetherOverviewUseCaseContract>(
      () => GetTogetherOverviewUseCase(getIt()),
    )
    ..registerLazySingleton<GetFriendChallengeTemplatesUseCaseContract>(
      () => GetFriendChallengeTemplatesUseCase(getIt()),
    )
    ..registerLazySingleton<CreateFriendChallengeUseCaseContract>(
      () => CreateFriendChallengeUseCase(getIt()),
    )
    ..registerLazySingleton<GetFriendChallengeUseCaseContract>(
      () => GetFriendChallengeUseCase(getIt()),
    )
    ..registerLazySingleton<JoinFriendChallengeUseCaseContract>(
      () => JoinFriendChallengeUseCase(getIt()),
    )
    ..registerLazySingleton<DeclineFriendChallengeUseCaseContract>(
      () => DeclineFriendChallengeUseCase(getIt()),
    )
    ..registerLazySingleton<LeaveFriendChallengeUseCaseContract>(
      () => LeaveFriendChallengeUseCase(getIt()),
    )
    ..registerLazySingleton<ReactToFriendChallengeUseCaseContract>(
      () => ReactToFriendChallengeUseCase(getIt()),
    )
    ..registerLazySingleton<RemoveFriendChallengeReactionUseCaseContract>(
      () => RemoveFriendChallengeReactionUseCase(getIt()),
    )
    ..registerLazySingleton<ProposeFriendStreakUseCaseContract>(
      () => ProposeFriendStreakUseCase(getIt()),
    )
    ..registerLazySingleton<AcceptFriendStreakUseCaseContract>(
      () => AcceptFriendStreakUseCase(getIt()),
    )
    ..registerLazySingleton<DeclineFriendStreakUseCaseContract>(
      () => DeclineFriendStreakUseCase(getIt()),
    )
    ..registerLazySingleton<EndFriendStreakUseCaseContract>(
      () => EndFriendStreakUseCase(getIt()),
    )
    ..registerLazySingleton<NudgeFriendStreakUseCaseContract>(
      () => NudgeFriendStreakUseCase(getIt()),
    )
    ..registerLazySingleton<CreateWorkoutTogetherUseCaseContract>(
      () => CreateWorkoutTogetherUseCase(getIt()),
    )
    ..registerLazySingleton<GetWorkoutTogetherUseCaseContract>(
      () => GetWorkoutTogetherUseCase(getIt()),
    )
    ..registerLazySingleton<FindWorkoutTogetherBySessionUseCaseContract>(
      () => FindWorkoutTogetherBySessionUseCase(getIt()),
    )
    ..registerLazySingleton<JoinWorkoutTogetherUseCaseContract>(
      () => JoinWorkoutTogetherUseCase(getIt()),
    )
    ..registerLazySingleton<DeclineWorkoutTogetherUseCaseContract>(
      () => DeclineWorkoutTogetherUseCase(getIt()),
    )
    ..registerLazySingleton<LeaveWorkoutTogetherUseCaseContract>(
      () => LeaveWorkoutTogetherUseCase(getIt()),
    )
    ..registerLazySingleton<StartWorkoutTogetherUseCaseContract>(
      () => StartWorkoutTogetherUseCase(getIt()),
    )
    ..registerLazySingleton<GetTogetherLimitsUseCaseContract>(
      () => GetTogetherLimitsUseCase(getIt()),
    )
    ..registerLazySingleton<CreateStudyRoomUseCaseContract>(
      () => CreateStudyRoomUseCase(getIt()),
    )
    ..registerLazySingleton<GetStudyRoomUseCaseContract>(
      () => GetStudyRoomUseCase(getIt()),
    )
    ..registerLazySingleton<JoinStudyRoomUseCaseContract>(
      () => JoinStudyRoomUseCase(getIt()),
    )
    ..registerLazySingleton<DeclineStudyRoomUseCaseContract>(
      () => DeclineStudyRoomUseCase(getIt()),
    )
    ..registerLazySingleton<LeaveStudyRoomUseCaseContract>(
      () => LeaveStudyRoomUseCase(getIt()),
    )
    ..registerLazySingleton<StartStudyRoomUseCaseContract>(
      () => StartStudyRoomUseCase(getIt()),
    )
    ..registerLazySingleton<ChooseStudyRoomSubjectUseCaseContract>(
      () => ChooseStudyRoomSubjectUseCase(getIt()),
    )
    ..registerLazySingleton<ReactInStudyRoomUseCaseContract>(
      () => ReactInStudyRoomUseCase(getIt()),
    )
    ..registerLazySingleton<ReportUserUseCaseContract>(
      () => ReportUserUseCase(getIt()),
    );
}
