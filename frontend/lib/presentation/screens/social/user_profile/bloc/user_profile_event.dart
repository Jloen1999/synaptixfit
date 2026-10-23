part of 'user_profile_bloc.dart';

@freezed
sealed class UserProfileEvent with _$UserProfileEvent {
  const factory UserProfileEvent.started(String userId) = UserProfileStarted;

  const factory UserProfileEvent.refreshed() = UserProfileRefreshed;

  const factory UserProfileEvent.nextPostsRequested() =
      UserProfileNextPostsRequested;

  const factory UserProfileEvent.likeToggled(String postId) =
      UserProfileLikeToggled;

  const factory UserProfileEvent.relationActionRequested(
    ProfileRelationAction action,
  ) = UserProfileRelationActionRequested;
}
