import 'package:freezed_annotation/freezed_annotation.dart';

import 'analytics_insight.dart';
import 'load_correlation.dart';
import 'rpe_trend.dart';
import 'training_volume.dart';
import 'weekly_analytics.dart';

part 'analytics_report.freezed.dart';

/// Toda la analítica de un periodo.
@freezed
abstract class AnalyticsReport with _$AnalyticsReport {
  const factory AnalyticsReport({
    required WeeklyAnalytics weekly,
    required TrainingVolume volume,
    required RpeTrend rpeTrend,
    required LoadCorrelation correlation,
    required List<AnalyticsInsight> insights,
  }) = _AnalyticsReport;
}
