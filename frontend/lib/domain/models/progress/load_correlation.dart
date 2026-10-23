import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/analytics_enums.dart';

part 'load_correlation.freezed.dart';

/// Correlación de Pearson entre horas de estudio y una métrica de entrenamiento.
///
/// [coefficient], [strength] y [direction] son nulos si no hay datos suficientes.
@freezed
abstract class LoadCorrelation with _$LoadCorrelation {
  const factory LoadCorrelation({
    required CorrelationMetric metric,
    double? coefficient,
    required int sampleSize,
    required int minimumSampleSize,
    required bool sufficientData,
    CorrelationStrength? strength,
    CorrelationDirection? direction,
    required List<CorrelationPoint> points,
  }) = _LoadCorrelation;
}

/// Una semana: horas de estudio frente al valor de entrenamiento.
@freezed
abstract class CorrelationPoint with _$CorrelationPoint {
  const factory CorrelationPoint({
    required DateTime weekStart,
    required double studyHours,
    required double trainingValue,
  }) = _CorrelationPoint;
}
