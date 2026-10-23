/// Dirección de la tendencia del RPE.
enum TrendDirection {
  up,
  down,
  stable,
  insufficientData;

  static TrendDirection fromApi(String? value) => switch (value) {
    'UP' => up,
    'DOWN' => down,
    'STABLE' => stable,
    _ => insufficientData,
  };
}

/// Métrica de entrenamiento que se cruza con las horas de estudio.
enum CorrelationMetric {
  rpe,
  minutes;

  String get apiValue => name.toUpperCase();

  static CorrelationMetric fromApi(String? value) =>
      value == 'MINUTES' ? minutes : rpe;
}

/// Fuerza de la correlación de Pearson.
enum CorrelationStrength {
  none,
  weak,
  moderate,
  strong,
  veryStrong;

  static CorrelationStrength? fromApi(String? value) => switch (value) {
    'NONE' => none,
    'WEAK' => weak,
    'MODERATE' => moderate,
    'STRONG' => strong,
    'VERY_STRONG' => veryStrong,
    _ => null,
  };
}

/// Signo de la correlación.
enum CorrelationDirection {
  positive,
  negative;

  static CorrelationDirection? fromApi(String? value) => switch (value) {
    'POSITIVE' => positive,
    'NEGATIVE' => negative,
    _ => null,
  };
}

/// Tipo de interpretación que devuelve la analítica.
enum InsightType {
  streak,
  consistency,
  volume,
  correlation,
  unknown;

  static InsightType fromApi(String? value) => switch (value) {
    'STREAK' => streak,
    'CONSISTENCY' => consistency,
    'VOLUME' => volume,
    'CORRELATION' => correlation,
    _ => unknown,
  };
}

/// Tono de una interpretación.
enum InsightSeverity {
  positive,
  info,
  warning;

  static InsightSeverity fromApi(String? value) => switch (value) {
    'POSITIVE' => positive,
    'WARNING' => warning,
    _ => info,
  };
}
