part of 'friend_challenge_form_bloc.dart';

@freezed
sealed class FriendChallengeFormEvent with _$FriendChallengeFormEvent {
  const factory FriendChallengeFormEvent.started() = FriendChallengeFormStarted;

  const factory FriendChallengeFormEvent.templateSelected(String templateId) =
      FriendChallengeFormTemplateSelected;

  const factory FriendChallengeFormEvent.daysChanged(int days) =
      FriendChallengeFormDaysChanged;

  const factory FriendChallengeFormEvent.modeChanged(FriendChallengeMode mode) =
      FriendChallengeFormModeChanged;

  const factory FriendChallengeFormEvent.submitted(List<String> friendIds) =
      FriendChallengeFormSubmitted;
}
