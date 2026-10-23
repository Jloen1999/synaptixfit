import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/analytics_enums.dart';

part 'analytics_insight.freezed.dart';

/// Interpretación estructurada de la analítica. La presentación redacta el texto
/// a partir de [type], [variant] y [params].
@freezed
abstract class AnalyticsInsight with _$AnalyticsInsight {
  const factory AnalyticsInsight({
    required InsightType type,
    required InsightSeverity severity,
    required String variant,
    @Default(<String, num>{}) Map<String, num> params,
  }) = _AnalyticsInsight;
}
