part of 'community_bloc.dart';

@freezed
sealed class CommunityEvent with _$CommunityEvent {
  const factory CommunityEvent.started() = CommunityStarted;

  const factory CommunityEvent.queryChanged(String query) =
      CommunityQueryChanged;

  const factory CommunityEvent.goalChanged(TrainingGoal? goal) =
      CommunityGoalChanged;

  const factory CommunityEvent.refreshed() = CommunityRefreshed;

  const factory CommunityEvent.moreRequested() = CommunityMoreRequested;

  const factory CommunityEvent.cloneRequested(String routineId) =
      CommunityCloneRequested;
}
