import 'dart:math' as math;

/// Servicio de cálculo de carga cognitiva acumulada.
///
/// Modela la fatiga atencional como un decaimiento exponencial agravado por
/// la falta de descanso. Combina acumulación logarítmica durante los bloques
/// de estudio con recuperación exponencial durante los periodos de descanso.
///
/// Fundamento (modelo híbrido de desintegración exponencial):
///
///   C_acum(n) = Σ[i=1..n] (1 − e^(−ρ·D_i)) · μ_i · e^(−λ·R_i)
///
///   A(t) = A₀ · e^(−β·t)
///
/// donde:
///   D_i  = duración del bloque i en minutos
///   μ_i  = multiplicador de dificultad de la asignatura
///   R_i  = tiempo de descanso antes del bloque i en minutos
///   ρ    = 0.1 (constante de disipación de fatiga, min⁻¹)
///   λ    = 0.05 (resistencia sistémica a la fatiga)
///   β    = 0.02 (constante de decaimiento atencional dentro del bloque)
class CognitiveLoadCalculatorService {
  const CognitiveLoadCalculatorService._();

  /// Constante de disipación de fatiga (min⁻¹).
  /// Calibrada empíricamente sobre la curva de la ley de potencia de la
  /// atención humana, reflejando la caída abrupta tras ~25 min de foco profundo.
  static const _rho = 0.1;

  /// Resistencia sistémica a la fatiga.
  /// Variable expandible a largo plazo por neuroplasticidad del hábito de estudio.
  static const _lambda = 0.05;

  /// Constante de decaimiento atencional dentro de un mismo bloque (min⁻¹).
  static const _beta = 0.02;

  /// Calcula la Carga Cognitiva Acumulada tras una secuencia de bloques.
  ///
  /// Recibe una lista de registros con:
  ///   - [duracionMin]: duración del bloque en minutos.
  ///   - [dificultad]: multiplicador de dificultad μ (1.0 baja, 1.3 media, 1.8 alta).
  ///   - [descansoMin]: minutos de descanso antes de iniciar este bloque.
  ///
  /// Retorna un valor adimensional en [0.0, 1.0] que cuantifica la tensión
  /// neurológica residual. Este valor opera como variable de estado principal
  /// en los algoritmos de regulación cruzada.
  static double calcularCargaAcumulada({
    required List<({double duracionMin, double dificultad, double descansoMin})>
        bloques,
  }) {
    double carga = 0.0;

    for (final b in bloques) {
      final acumulacion = (1 - math.exp(-_rho * b.duracionMin)) * b.dificultad;
      final recuperacion = math.exp(-_lambda * b.descansoMin);
      carga += acumulacion * recuperacion;
    }

    return carga.clamp(0.0, 1.0);
  }

  /// Calcula la capacidad atencional disponible en tiempo real dentro de un bloque.
  ///
  /// [capacidadInicial] — capacidad al inicio del bloque (típicamente 1.0).
  /// [minutosTranscurridos] — tiempo continuo dentro del bloque.
  ///
  /// Retorna un valor en [0.0, 1.0] que decrece exponencialmente con el tiempo
  /// en la tarea (time-on-task).
  static double capacidadAtencional({
    required double capacidadInicial,
    required int minutosTranscurridos,
  }) {
    if (minutosTranscurridos <= 0) return capacidadInicial;
    return capacidadInicial * math.exp(-_beta * minutosTranscurridos);
  }

  /// Deriva el multiplicador de dificultad según la complejidad de la asignatura.
  ///
  /// - 'alta' → 1.8 (matemáticas de alto nivel, programación profunda, idiomas).
  /// - 'media' → 1.3 (lectura comprensiva, escritura analítica).
  /// - 'baja' / null → 1.0 (lectura pasiva, repaso ligero).
  static double dificultadAsignatura(String? dificultad) {
    if (dificultad == null) return 1.0;
    return switch (dificultad.trim().toLowerCase()) {
      'alta' => 1.8,
      'media' => 1.3,
      _ => 1.0,
    };
  }
}
