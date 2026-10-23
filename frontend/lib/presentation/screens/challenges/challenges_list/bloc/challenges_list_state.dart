part of 'challenges_list_bloc.dart';

enum ChallengesListStatus { loading, ready, failure }

@freezed
abstract class ChallengesListState with _$ChallengesListState {
  const factory ChallengesListState({
    @Default(ChallengesListStatus.loading) ChallengesListStatus status,
    @Default(ChallengeQuery()) ChallengeQuery query,
    @Default(<Challenge>[]) List<Challenge> challenges,
    @Default(0) int page,
    @Default(false) bool hasMore,

    /// Recargando el listado tras cambiar los filtros.
    @Default(false) bool listLoading,
    @Default(false) bool loadingMore,
    @Default(ChallengeSummary.empty) ChallengeSummary summary,
    @Default(<PendingMilestone>[]) List<PendingMilestone> pending,

    /// Tareas pendientes que se están completando.
    @Default(<String>{}) Set<String> busyMilestoneIds,
    AppError? error,

    /// Efecto de un solo uso (aviso o error de una acción).
    ChallengesListEffect? effect,
  }) = _ChallengesListState;
}

@freezed
sealed class ChallengesListEffect with _$ChallengesListEffect {
  /// Tarea completada; [account] es la cuenta refrescada si cambió la XP.
  const factory ChallengesListEffect.milestoneCompleted({
    required int xpDelta,
    required int unlockedCount,
    required bool challengeCompleted,
    Account? account,
  }) = ChallengesListMilestoneCompleted;

  const factory ChallengesListEffect.failure(AppError error) =
      ChallengesListActionFailed;
}
