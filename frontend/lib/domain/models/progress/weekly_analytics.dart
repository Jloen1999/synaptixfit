import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/analytics_period.dart';

part 'weekly_analytics.freezed.dart';

/// Métricas de entrenamiento agregadas por semana y totales del periodo.
@freezed
abstract class WeeklyAnalytics with _$WeeklyAnalytics {
  const factory WeeklyAnalytics({
    required AnalyticsPeriod period,
    required List<WeekMetric> weeks,
    required int totalSessions,
    required int totalMinutes,
    required int totalCalories,
    double? averageRpe,
  }) = _WeeklyAnalytics;

  const WeeklyAnalytics._();

  bool get hasData => totalSessions > 0;
}

/// Métricas de una semana (lunes a domingo).
@freezed
abstract class WeekMetric with _$WeekMetric {
  const factory WeekMetric({
    required DateTime weekStart,
    required int sessions,
    double? averageRpe,
    required int totalMinutes,
    required int totalCalories,
  }) = _WeekMetric;
}
