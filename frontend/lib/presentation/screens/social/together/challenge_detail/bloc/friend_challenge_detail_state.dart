part of 'friend_challenge_detail_bloc.dart';

enum FriendChallengeDetailStatus { loading, ready, failure }

/// Efecto de un solo uso tras salir o decir que no.
enum FriendChallengeDetailEffect { left, declined }

@freezed
abstract class FriendChallengeDetailState with _$FriendChallengeDetailState {
  const factory FriendChallengeDetailState({
    String? id,
    @Default(FriendChallengeDetailStatus.loading)
    FriendChallengeDetailStatus status,
    FriendChallenge? challenge,
    AppError? error,
    @Default(false) bool busy,
    FriendChallengeDetailEffect? effect,
    AppError? actionError,
  }) = _FriendChallengeDetailState;
}
