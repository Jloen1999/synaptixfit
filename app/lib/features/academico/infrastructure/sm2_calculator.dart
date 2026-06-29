/// Calculadora del algoritmo SM-2 (SuperMemo 2) para repetición espaciada.
///
/// Parámetros:
/// - EF (facilidad): inicial 2.5, rango [1.3, 2.5]
/// - I (intervalo): días hasta el próximo repaso
/// - n (repasos_ok): conteo de repasos correctos consecutivos
///
/// calidad: 0 = "Toca repasar", 1 = "Me cuesta", 2 = "Dominio absoluto"
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
  static const _facilidadInicial = 2.5;
  static const _facilidadMinima = 1.3;

  /// Calcula el nuevo estado SM-2 a partir del estado anterior y la calidad
  /// de la respuesta (0: repasar, 1: cuesta, 2: dominado).
  static Sm2Resultado calcular({
    required int calidad,
    required int intervaloActualDias,
    required double facilidad,
    required int repasosCompletados,
  }) {
    if (calidad < 0 || calidad > 2) {
      throw ArgumentError('calidad debe ser 0, 1 o 2');
    }

    int nuevoIntervalo;
    int nuevosRepasos;
    String estadoDominio;

    if (calidad < 2) {
      nuevosRepasos = 0;
      nuevoIntervalo = 1;
      estadoDominio = calidad == 0 ? 'necesita_repaso' : 'en_progreso';
    } else {
      switch (repasosCompletados) {
        case 0:
          nuevoIntervalo = 1;
        case 1:
          nuevoIntervalo = 3;
        case 2:
          nuevoIntervalo = 7;
        default:
          nuevoIntervalo = (intervaloActualDias * facilidad).ceil();
          if (nuevoIntervalo < 1) nuevoIntervalo = 1;
      }
      nuevosRepasos = repasosCompletados + 1;
      estadoDominio = nuevosRepasos >= 3 ? 'dominado' : 'en_progreso';
    }

    double nuevaFacilidad =
        facilidad + (0.1 - (2 - calidad) * (0.08 + (2 - calidad) * 0.02));
    if (nuevaFacilidad > _facilidadInicial) nuevaFacilidad = _facilidadInicial;
    if (nuevaFacilidad < _facilidadMinima) nuevaFacilidad = _facilidadMinima;

    return Sm2Resultado(
      intervaloDias: nuevoIntervalo,
      facilidad: nuevaFacilidad,
      repasosCompletados: nuevosRepasos,
      estadoDominio: estadoDominio,
    );
  }
}
