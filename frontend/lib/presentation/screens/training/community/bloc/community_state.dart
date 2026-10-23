part of 'community_bloc.dart';

enum CommunityStatus { loading, ready, failure }

@freezed
abstract class CommunityState with _$CommunityState {
  const factory CommunityState({
    @Default(CommunityStatus.loading) CommunityStatus status,
    @Default('') String query,
    TrainingGoal? goal,
    @Default(<RoutineSummary>[]) List<RoutineSummary> items,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,
    @Default(false) bool refreshing,

    /// Rutina que se está clonando.
    String? cloningId,
    AppError? error,
    TrainingEffect? effect,
  }) = _CommunityState;
}
