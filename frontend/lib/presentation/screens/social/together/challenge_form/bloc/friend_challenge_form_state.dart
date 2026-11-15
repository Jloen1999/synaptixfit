part of 'friend_challenge_form_bloc.dart';

enum FriendChallengeFormStatus { loading, ready, failure }

@freezed
abstract class FriendChallengeFormState with _$FriendChallengeFormState {
  const factory FriendChallengeFormState({
    @Default(FriendChallengeFormStatus.loading)
    FriendChallengeFormStatus status,
    @Default(<ChallengeTemplate>[]) List<ChallengeTemplate> templates,
    String? templateId,
    @Default(7) int days,
    @Default(FriendChallengeMode.cooperative) FriendChallengeMode mode,
    @Default(false) bool saving,
    AppError? error,

    /// Reto creado (efecto de un solo uso: abrirlo).
    FriendChallenge? created,
    AppError? saveError,
  }) = _FriendChallengeFormState;
}
