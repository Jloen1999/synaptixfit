part of 'community_challenges_bloc.dart';

@freezed
sealed class CommunityChallengesEvent with _$CommunityChallengesEvent {
  const factory CommunityChallengesEvent.started() = CommunityChallengesStarted;

  const factory CommunityChallengesEvent.refreshed() =
      CommunityChallengesRefreshed;

  /// Sustituye los filtros (un valor nulo quita ese filtro).
  const factory CommunityChallengesEvent.filtersChanged({
    ChallengeType? type,
    String? search,
  }) = CommunityChallengesFiltersChanged;

  const factory CommunityChallengesEvent.loadMoreRequested() =
      CommunityChallengesLoadMoreRequested;

  const factory CommunityChallengesEvent.cloneRequested(String challengeId) =
      CommunityChallengesCloneRequested;
}
