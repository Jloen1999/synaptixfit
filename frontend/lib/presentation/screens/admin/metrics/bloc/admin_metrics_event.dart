part of 'admin_metrics_bloc.dart';

@freezed
sealed class AdminMetricsEvent with _$AdminMetricsEvent {
  const factory AdminMetricsEvent.started() = AdminMetricsStarted;

  const factory AdminMetricsEvent.refreshed() = AdminMetricsRefreshed;

  const factory AdminMetricsEvent.trendDaysChanged(int days) =
      AdminMetricsTrendDaysChanged;
}
