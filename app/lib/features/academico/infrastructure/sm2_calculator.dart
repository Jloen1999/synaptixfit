import 'dart:math' as math;

/// Calculadora del algoritmo SM-2 (SuperMemo 2) para repetición espaciada.
///
/// Ampliada a escala 0-5 para el sistema SM-2-Physio, con soporte de
/// calidad continua (double) para preservar la precisión asintótica de la
/// curva de Ebbinghaus en el cálculo del Factor de Facilidad (EF).
///
/// Parámetros:
/// - EF (facilidad): inicial 2.5, rango [1.3, 3.0]
/// - I (intervalo): días hasta el próximo repaso
/// - n (repasos_ok): conteo de repasos correctos consecutivos
///
/// calidad (0.0–5.0):
///   0.0 = "Olvido total", 1.0 = "Casi nada", 2.0 = "Con dificultad",
///   3.0 = "Con esfuerzo", 4.0 = "Casi perfecto", 5.0 = "Perfecto"
///
/// IMPORTANTE: la variable `calidad` se recibe como double continuo.
/// Solo los condicionales lógicos (fallo/éxito, estado) usan .round().
/// La fórmula EF usa el valor double exacto sin redondeo.
class Sm2Resultado {
  const Sm2Resultado({
    required this.intervaloDias,
    required this.facilidad,
    required this.repasosCompletados,
    required this.estadoDominio,
  });

  final int intervaloDias;
  final double facilidad;
  final int repasosCompletados;
  final String estadoDominio;
}

class Sm2Calculator {
  static const _facilidadMinima = 1.3;
  static const _facilidadMaxima = 3.0;

  /// Calcula el nuevo estado SM-2 a partir del estado anterior y la calidad
  /// de la respuesta.
  ///
  /// [calidad] — valor continuo [0.0, 5.0] (sin redondeo para la fórmula EF).
  ///   Se usa .round() exclusivamente para condicionales lógicos.
  static Sm2Resultado calcular({
    required double calidad,
    required int intervaloActualDias,
    required double facilidad,
    required int repasosCompletados,
  }) {
    final calidadDiscreta = calidad.round().clamp(0, 5);

    int nuevoIntervalo;
    int nuevosRepasos;
    String estadoDominio;

    // Umbral de fallo: calidad < 3 → reset de repasos
    if (calidadDiscreta < 3) {
      nuevosRepasos = 0;
      nuevoIntervalo = 1;
      estadoDominio = calidadDiscreta <= 1 ? 'necesita_repaso' : 'en_progreso';
    } else {
      switch (repasosCompletados) {
        case 0:
          nuevoIntervalo = 1;
        case 1:
          nuevoIntervalo = 3;
        case 2:
          nuevoIntervalo = 7;
        default:
          nuevoIntervalo =
              math.max(1, (intervaloActualDias * facilidad).ceil());
      }
      nuevosRepasos = repasosCompletados + 1;
      estadoDominio = nuevosRepasos >= 3 ? 'dominado' : 'en_progreso';
    }

    // Fórmula EF con calidad continua (double exacto, sin redondeo):
    // EF_new = EF + (0.1 − (5−q)·(0.08+(5−q)·0.02))
    final deltaEf = 0.1 - (5 - calidad) * (0.08 + (5 - calidad) * 0.02);
    double nuevaFacilidad = facilidad + deltaEf;

    if (nuevaFacilidad > _facilidadMaxima) nuevaFacilidad = _facilidadMaxima;
    if (nuevaFacilidad < _facilidadMinima) nuevaFacilidad = _facilidadMinima;

    return Sm2Resultado(
      intervaloDias: nuevoIntervalo,
      facilidad: nuevaFacilidad,
      repasosCompletados: nuevosRepasos,
      estadoDominio: estadoDominio,
    );
  }
}
