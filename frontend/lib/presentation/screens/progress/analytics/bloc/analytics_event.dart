part of 'analytics_bloc.dart';

@freezed
sealed class AnalyticsEvent with _$AnalyticsEvent {
  /// Carga (o recarga) el periodo actual.
  const factory AnalyticsEvent.started() = AnalyticsStarted;

  const factory AnalyticsEvent.periodChanged(AnalyticsPeriod period) =
      AnalyticsPeriodChanged;

  /// Cambia la métrica de la correlación (RPE o minutos).
  const factory AnalyticsEvent.metricChanged(CorrelationMetric metric) =
      AnalyticsMetricChanged;
}
