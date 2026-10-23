part of 'community_challenges_bloc.dart';

enum CommunityChallengesStatus { loading, ready, failure }

@freezed
abstract class CommunityChallengesState with _$CommunityChallengesState {
  const factory CommunityChallengesState({
    @Default(CommunityChallengesStatus.loading)
    CommunityChallengesStatus status,
    ChallengeType? type,
    String? search,
    @Default(<Challenge>[]) List<Challenge> challenges,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool listLoading,
    @Default(false) bool loadingMore,

    /// Reto que se está clonando.
    String? cloningId,
    AppError? error,
    CommunityChallengesEffect? effect,
  }) = _CommunityChallengesState;
}

@freezed
sealed class CommunityChallengesEffect with _$CommunityChallengesEffect {
  /// Copia creada (privada y sin progreso).
  const factory CommunityChallengesEffect.cloned(Challenge challenge) =
      CommunityChallengeCloned;

  const factory CommunityChallengesEffect.failure(AppError error) =
      CommunityChallengesActionFailed;
}
