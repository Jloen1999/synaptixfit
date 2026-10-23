import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/analytics_enums.dart';

part 'rpe_trend.freezed.dart';

/// Evolución semanal del esfuerzo percibido (RPE) y su tendencia.
@freezed
abstract class RpeTrend with _$RpeTrend {
  const factory RpeTrend({
    required List<RpePoint> points,
    double? slopePerWeek,
    required TrendDirection direction,
  }) = _RpeTrend;
}

/// RPE medio de una semana.
@freezed
abstract class RpePoint with _$RpePoint {
  const factory RpePoint({
    required DateTime weekStart,
    required double averageRpe,
  }) = _RpePoint;
}
