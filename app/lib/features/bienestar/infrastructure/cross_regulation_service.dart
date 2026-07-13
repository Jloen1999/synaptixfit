import 'dart:math' as math;

/// Servicio de regulación cruzada entre dominios académico y físico.
///
/// Implementa los algoritmos de retroalimentación algorítmica bidireccional
/// basados en:
///   - Teoría del Gobernador Central (Noakes, 1997).
///   - Modelo ACWR de carga aguda/crónica (Gabbett, 2016).
///   - Hipótesis de fatiga mental → rendimiento físico (Marcora, 2009).
///
/// Fórmulas:
///
/// A) Estrés académico → reduce volumen deportivo:
///   V_mod = V_base · (1 − λ_s · min(1, (C_acum/C_max) · e^(−σ·D_exam)))
///
/// B) Fatiga física → acorta bloques de estudio (T_max):
///   Si ACWR ≤ 1.3:       T_max = T_base
///   Si 1.3 < ACWR ≤ 2.0: T_max = T_base · (1 − α · ln(ACWR/1.3))
///   Si ACWR > 2.0:       T_max = T_base · 0.5
class CrossRegulationService {
  const CrossRegulationService._();

  /// Sensibilidad de calendario académico.
  /// Determina cuán rápido crece la penalización al acercarse un examen.
  static const _sigma = 0.15;

  /// Severidad de descarga deportiva (deloading).
  /// Rango 0.30–0.50: garantiza que incluso en pánico académico extremo
  /// la recomendación no baje de un 50–70% del volumen base.
  static const _lambdaS = 0.40;

  /// Amortiguación sistémica cognitiva.
  /// Controla la pendiente de la penalización logarítmica del T_max.
  static const _alpha = 0.5;

  /// ──── A) Estrés académico → reduce volumen deportivo ────

  /// Calcula el factor de volumen modificado por estrés académico.
  ///
  /// [volumenBase] — volumen planificado original (1.0 = sin modificación).
  /// [cargaCognitiva] — valor actual de C_acum (0.0–1.0).
  /// [cargaMaxima] — techo cognitivo empírico C_max (típicamente 1.0).
  /// [diasHastaExamen] — días restantes hasta el evento académico crítico.
  ///
  /// Retorna un factor de ajuste en [0.0, 1.0] a multiplicar por el volumen.
  /// Si el examen está a más de 60 días, no hay penalización.
  static double calcularVolumenModificado({
    required double volumenBase,
    required double cargaCognitiva,
    required double cargaMaxima,
    required int diasHastaExamen,
  }) {
    if (diasHastaExamen > 60 || cargaMaxima == 0) return volumenBase;

    final factorEstres = (cargaCognitiva / cargaMaxima).clamp(0.0, 1.0);
    final factorUrgencia = math.exp(-_sigma * diasHastaExamen);
    final penalizacion =
        _lambdaS * (factorEstres * factorUrgencia).clamp(0.0, 1.0);

    return volumenBase * (1.0 - penalizacion);
  }

  /// ──── B) Fatiga física → acorta bloques de estudio ────

  /// Calcula el tiempo máximo recomendado para un bloque de estudio.
  ///
  /// [tBaseMinutos] — capacidad endurante habitual de enfoque (default: 90).
  /// [acwr] — ratio de carga aguda/crónica actual del usuario.
  ///
  /// Zonas:
  ///   ACWR ≤ 1.3 → zona óptima (sin penalización).
  ///   1.3 < ACWR ≤ 2.0 → zona de peligro (penalización logarítmica).
  ///   ACWR > 2.0 → zona de sobreentrenamiento (hard cap al 50%).
  ///
  /// Valor mínimo de retorno: 25 minutos.
  static int calcularTmaxEstudio({
    required int tBaseMinutos,
    required double acwr,
  }) {
    if (acwr <= 1.3) return tBaseMinutos;

    if (acwr <= 2.0) {
      final penalizacion = _alpha * math.log(acwr / 1.3);
      return (tBaseMinutos * (1 - penalizacion))
          .round()
          .clamp(25, tBaseMinutos);
    }

    return (tBaseMinutos * 0.5).round().clamp(25, tBaseMinutos);
  }
}
