part of 'analytics_bloc.dart';

enum AnalyticsStatus { loading, loaded, failure }

@freezed
abstract class AnalyticsState with _$AnalyticsState {
  const factory AnalyticsState({
    @Default(AnalyticsPeriod.monthly) AnalyticsPeriod period,
    @Default(CorrelationMetric.rpe) CorrelationMetric metric,
    @Default(AnalyticsStatus.loading) AnalyticsStatus status,

    /// Último informe cargado; se conserva mientras se recarga otro periodo.
    AnalyticsReport? report,
    AppError? error,
    @Default(false) bool correlationLoading,
    AppError? correlationError,
  }) = _AnalyticsState;
}
