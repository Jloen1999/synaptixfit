import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/analytics_period.dart';

part 'weekly_analytics.freezed.dart';

/// Métricas de entrenamiento agregadas por semana y totales del periodo.
@freezed
abstract class WeeklyAnalytics with _$WeeklyAnalytics {
  const factory WeeklyAnalytics({
    required AnalyticsPeriod period,
    required List<WeekMetric> weeks,

    /// Lunes de la semana en curso, tal como la declara el servidor.
    DateTime? currentWeekStart,
    required int totalSessions,
    required int totalMinutes,
    required int totalCalories,
    double? averageRpe,
  }) = _WeeklyAnalytics;

  const WeeklyAnalytics._();

  bool get hasData => totalSessions > 0;

  /// Semana en curso: la que el servidor declara como actual (la serie trae
  /// ceros si no hubo entreno). Nula si no viene.
  WeekMetric? get currentWeek {
    final start = currentWeekStart;
    if (start == null) return null;
    for (final w in weeks) {
      final d = w.weekStart;
      if (d.year == start.year &&
          d.month == start.month &&
          d.day == start.day) {
        return w;
      }
    }
    return null;
  }
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
