/// Servicio SM-2-Physio: recálculo en la sombra basado en fatiga física.
///
/// Fundamento (Hipótesis de Fatiga Central — Meeusen, Newsholme):
///
/// El ejercicio físico intenso altera el ecosistema bioquímico cerebral.
/// La captación periférica de BCAA eleva la proporción de triptófano libre
/// en sangre, aumentando la síntesis de serotonina (5-HT) en el SNC. Esto
/// deteriora temporalmente la evocación mnésica sin implicar pérdida real
/// de retención a largo plazo.
///
/// Un fallo en la tarjeta durante esta ventana de fatiga serotoninérgica
/// no refleja una fisura en la red de retención. Para evitar que el algoritmo
/// SM-2 castigue injustamente el Factor de Facilidad (EF), se aplica un
/// coeficiente de indulgencia neuronal que modifica la calificación percibida.
///
/// Fórmula:
///   Q_adj = Q_real + η · (cargaFisicaHoy / cargaFisicaMaximaHistoria)
///
/// donde:
///   η = 0.5 (constante de indulgencia neuronal)
///   Q_real ∈ [0, 5] (escala ampliada: 0=blackout, 5=recuerdo fotográfico)
///   cargaFisicaHoy = AU del día actual (session_rpe × duración_minutos)
///   cargaFisicaMaxima = máxima AU diaria registrada en el historial
///
/// IMPORTANTE:
/// - No existe función de mapeo a escala 0-2.
/// - Q_adj se retorna como double continuo [0.0, 5.0].
/// - Prohibido redondear Q_adj a entero antes de la fórmula EF. La curva de
///   Ebbinghaus necesita la fracción decimal precisa. Solo los condicionales
///   lógicos (if calidad < 3) usan .round() para determinar fallo/éxito.
/// - Este recálculo opera en la sombra: el usuario nunca ve Q_adj, solo el
///   intervalo resultante.
class Sm2PhysioService {
  const Sm2PhysioService._();

  /// Constante de indulgencia neuronal (η).
  ///
  /// Magnitud del perdón fisiológico. Un valor de 0.5 significa que en el día
  /// más duro del historial biomecánico (ratio = 1.0), se añade hasta medio
  /// punto a la calificación real del usuario.
  static const _indulgenciaNeuronal = 0.5;

  /// Calcula la calificación de calidad ajustada (Q_adj).
  ///
  /// [qReal] — respuesta cruda del usuario en escala 0-5.
  /// [cargaFisicaHoy] — carga AU acumulada en el día actual.
  /// [cargaFisicaMaxima] — máxima carga AU diaria registrada en el historial.
  ///
  /// Retorna un valor decimal continuo en [0.0, 5.0] que se usará directamente
  /// en la fórmula del Factor de Facilidad del SM-2. No se redondea a entero;
  /// la precisión decimal es necesaria para la curva de Ebbinghaus.
  static double calcularQAdj({
    required int qReal,
    required double cargaFisicaHoy,
    required double cargaFisicaMaxima,
  }) {
    if (cargaFisicaMaxima <= 0) return qReal.toDouble();

    final ratio = (cargaFisicaHoy / cargaFisicaMaxima).clamp(0.0, 1.0);
    return (qReal + _indulgenciaNeuronal * ratio).clamp(0.0, 5.0);
  }
}
