part of 'wellness_history_bloc.dart';

enum WellnessHistoryStatus { loading, ready, failure }

@freezed
abstract class WellnessHistoryState with _$WellnessHistoryState {
  const factory WellnessHistoryState({
    @Default(WellnessHistoryStatus.loading) WellnessHistoryStatus status,

    /// Registros de peso en orden cronológico.
    @Default(<WeightRecord>[]) List<WeightRecord> weights,
    @Default(<GoalHistoryEntry>[]) List<GoalHistoryEntry> goals,
    AppError? error,
  }) = _WellnessHistoryState;
}
