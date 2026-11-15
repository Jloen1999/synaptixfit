part of 'friend_challenge_detail_bloc.dart';

@freezed
sealed class FriendChallengeDetailEvent with _$FriendChallengeDetailEvent {
  const factory FriendChallengeDetailEvent.started(String id) =
      FriendChallengeDetailStarted;

  /// Aceptar la invitación, o «Deshacer» tras salir.
  const factory FriendChallengeDetailEvent.joined() =
      FriendChallengeDetailJoined;

  const factory FriendChallengeDetailEvent.declined() =
      FriendChallengeDetailDeclined;

  const factory FriendChallengeDetailEvent.left() = FriendChallengeDetailLeft;

  const factory FriendChallengeDetailEvent.reactionTapped(
    FriendChallengeBoardEntry entry,
    TogetherReaction reaction,
  ) = FriendChallengeDetailReactionTapped;
}
