part of 'admin_metrics_bloc.dart';

@freezed
abstract class AdminMetricsState with _$AdminMetricsState {
  const factory AdminMetricsState({
    @Default(AdminStatus.initial) AdminStatus status,
    PlatformMetrics? metrics,
    @Default(<DailyActivity>[]) List<DailyActivity> trend,
    @Default(30) int trendDays,
    @Default(false) bool trendLoading,
    AppError? trendError,
    AppError? error,
  }) = _AdminMetricsState;
}
