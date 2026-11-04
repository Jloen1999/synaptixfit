part of 'activity_history_bloc.dart';

@freezed
abstract class ActivityHistoryState with _$ActivityHistoryState {
  const factory ActivityHistoryState({
    @Default(true) bool loading,
    @Default(false) bool loadingMore,
    @Default(<SportActivity>[]) List<SportActivity> items,
    @Default(0) int page,
    @Default(false) bool hasMore,
    AppError? error,
  }) = _ActivityHistoryState;
}
