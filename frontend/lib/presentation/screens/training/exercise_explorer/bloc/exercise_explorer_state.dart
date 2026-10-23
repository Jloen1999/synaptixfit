part of 'exercise_explorer_bloc.dart';

enum ExplorerStatus { loading, ready, failure }

@freezed
abstract class ExerciseExplorerState with _$ExerciseExplorerState {
  const factory ExerciseExplorerState({
    @Default(ExplorerStatus.loading) ExplorerStatus status,
    @Default(ExerciseSearchCriteria()) ExerciseSearchCriteria criteria,
    ExerciseFilterOptions? filters,
    @Default(<Exercise>[]) List<Exercise> items,
    @Default(0) int page,
    @Default(0) int totalItems,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,
    AppError? error,
  }) = _ExerciseExplorerState;
}
