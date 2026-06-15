// ---------------------------------------------------------------------------
// DTO para insights generados a partir de correlaciones entre variables
// academicas y de entrenamiento.
// ---------------------------------------------------------------------------

class InsightCorrelacion {
  const InsightCorrelacion({
    required this.titulo,
    required this.coeficiente,
    required this.interpretacion,
    required this.recomendacion,
  });

  /// Titulo breve del insight (ej: "Carga academica vs RPE").
  final String titulo;

  /// Coeficiente de correlacion de Pearson (-1.0 a 1.0).
  final double coeficiente;

  /// Interpretacion en lenguaje natural del resultado.
  final String interpretacion;

  /// Recomendacion accionable basada en la correlacion.
  final String recomendacion;

  /// Magnitud de la correlacion en terminos cualitativos.
  String get magnitud {
    final abs = coeficiente.abs();
    if (abs >= 0.8) return 'muy fuerte';
    if (abs >= 0.6) return 'fuerte';
    if (abs >= 0.4) return 'moderada';
    if (abs >= 0.2) return 'debil';
    return 'muy debil o nula';
  }

  /// Direccion de la correlacion.
  String get direccion => coeficiente >= 0 ? 'positiva' : 'negativa';
}
