import 'dart:math';

import '../application/rutina_provider.dart';
import 'parametros_objetivo.dart';

class SerieRealizadaDto {
  final int numeroSerie;
  final int? repeticionesRealizadas;
  final double? pesoKg;
  final bool completada;
  final int failedReps;

  const SerieRealizadaDto({
    required this.numeroSerie,
    this.repeticionesRealizadas,
    this.pesoKg,
    this.completada = false,
    this.failedReps = 0,
  });
}

class ProgresionEjercicio {
  final String ejercicioId;
  final int nuevasSeries;
  final int nuevasRepeticiones;
  final int nuevoDescanso;
  final double? nuevoPeso;
  final List<double>? pesosPorSerie;
  final int? nuevaDuracionSegundos;
  final int? nuevaDistanciaMetros;
  final int? nuevoTiempoIsometricoSegundos;
  final String? log;

  const ProgresionEjercicio({
    required this.ejercicioId,
    required this.nuevasSeries,
    required this.nuevasRepeticiones,
    required this.nuevoDescanso,
    this.nuevoPeso,
    this.pesosPorSerie,
    this.nuevaDuracionSegundos,
    this.nuevaDistanciaMetros,
    this.nuevoTiempoIsometricoSegundos,
    this.log,
  });
}

class ProgresionCalculator {
  // ---------------------------------------------------------------------------
  // 1RM — fórmula no lineal (investigación del usuario)
  // ---------------------------------------------------------------------------

  static double calcular1RM(double pesoKg, int reps) {
    if (reps <= 0 || pesoKg <= 0) return 0;
    if (reps == 1) return pesoKg;
    if (pesoKg < 3.0) return pesoKg * (1 + 0.0333 * reps);
    return pesoKg * (1 + pow(reps - 1, 0.85) / (-2.55 + 4.58 * log(pesoKg)));
  }

  // ---------------------------------------------------------------------------
  // Pesos por serie (warming ramp)
  // ---------------------------------------------------------------------------

  static List<double> generarPesosPorSerie({
    required double pesoObjetivo,
    required int totalSeries,
  }) {
    if (totalSeries <= 1) return [pesoObjetivo];
    final pesos = <double>[];
    for (var i = 1; i <= totalSeries; i++) {
      if (i == 1 && totalSeries >= 3) {
        pesos.add(pesoObjetivo * 0.50); // warm-up
      } else if (i == 2 && totalSeries >= 3) {
        pesos.add(pesoObjetivo * 0.75); // build-up
      } else {
        pesos.add(pesoObjetivo); // working sets
      }
    }
    return pesos;
  }

  // ---------------------------------------------------------------------------
  // Doble progresión
  // ---------------------------------------------------------------------------

  ProgresionEjercicio calcularProgresion({
    required String ejercicioId,
    required int seriesActuales,
    required int repeticionesActuales,
    required int descansoActual,
    required double? pesoActual,
    required List<String> tipoMedicion,
    required double rpeUltimaSesion,
    List<SerieRealizadaDto> seriesRealizadas = const [],
    ParametrosObjetivo? params,
    int? duracionActual,
    int? distanciaActual,
    int? tiempoIsometricoActual,
  }) {
    double? peso = pesoActual;
    int series = seriesActuales;
    int reps = repeticionesActuales;
    int descanso = descansoActual;
    int? duracion = duracionActual;
    int? distancia = distanciaActual;
    int? tiempoIso = tiempoIsometricoActual;
    final log = <String>[];
    final usaPeso = tipoMedicion.contains('peso');
    final usaReps = tipoMedicion.contains('repeticiones');
    final usaTiempo = tipoMedicion.contains('tiempo');
    final usaDistancia = tipoMedicion.contains('distancia');
    final esIsometrico =
        usaTiempo && !usaReps && tiempoIsometricoActual != null;

    final totalFailed =
        seriesRealizadas.fold<int>(0, (sum, s) => sum + s.failedReps);

    if (totalFailed > 0) {
      final factor = (100 - (totalFailed * 5)).clamp(70, 95) / 100.0;
      if (usaPeso && peso != null) peso = peso * factor;
      if (usaTiempo && duracion != null) {
        duracion = (duracion * factor).round();
      }
      if (usaDistancia && distancia != null) {
        distancia = (distancia * factor).round();
      }
      if (esIsometrico && tiempoIso != null) {
        tiempoIso = (tiempoIso * factor).round();
      }
      if (params != null) {
        series = (series - 1).clamp(params.seriesMin, params.seriesMax);
      }
      log.add('-$totalFailed fallos → carga ×${factor.toStringAsFixed(2)}');
    } else if (rpeUltimaSesion >= 9.5) {
      if (usaPeso && peso != null) peso = peso * 0.85;
      if (usaTiempo && duracion != null) {
        duracion = (duracion * 0.85).round();
      }
      if (usaDistancia && distancia != null) {
        distancia = (distancia * 0.85).round();
      }
      if (esIsometrico && tiempoIso != null) {
        tiempoIso = (tiempoIso * 0.85).round();
      }
      log.add(
          'RPE ${rpeUltimaSesion.toStringAsFixed(1)} (muy alto) → carga -15%');
    } else if (rpeUltimaSesion <= 5.0) {
      if (usaPeso && peso != null) peso = peso * 1.10;
      if (usaTiempo && duracion != null) {
        duracion = (duracion * 1.10).round();
      }
      if (usaDistancia && distancia != null) {
        distancia = (distancia * 1.10).round();
      }
      if (esIsometrico && tiempoIso != null) {
        tiempoIso = (tiempoIso + 10).clamp(5, 300);
      }
      log.add(
          'RPE ${rpeUltimaSesion.toStringAsFixed(1)} (muy bajo) → carga +10%');
    } else if (rpeUltimaSesion <= 7.0) {
      if (usaPeso && usaReps && peso != null) {
        if (repeticionesActuales >= (params?.repsMax ?? 15)) {
          peso = peso * 1.05;
          reps = params?.repsMin ?? 6;
          log.add(
              'RPE ${rpeUltimaSesion.toStringAsFixed(1)} (bajo) → +5% peso, reps reset');
        } else {
          reps = repeticionesActuales + 1;
          log.add('RPE ${rpeUltimaSesion.toStringAsFixed(1)} (bajo) → +1 rep');
        }
      } else if (usaTiempo && duracion != null) {
        duracion = (duracion * 1.10).round();
        log.add('RPE bajo → TUT +10%');
      } else if (usaDistancia && distancia != null) {
        distancia = (distancia * 1.10).round();
        log.add('RPE bajo → distancia +10%');
      }
    }

    if (params != null) {
      series = series.clamp(params.seriesMin, params.seriesMax);
      reps = reps.clamp(params.repsMin, params.repsMax);
      descanso = descanso.clamp(params.descansoMin, params.descansoMax);
    }

    final pesosPorSerie = (usaPeso && peso != null && peso > 0)
        ? generarPesosPorSerie(pesoObjetivo: peso, totalSeries: series)
        : null;

    return ProgresionEjercicio(
      ejercicioId: ejercicioId,
      nuevasSeries: series,
      nuevasRepeticiones: reps,
      nuevoDescanso: descanso,
      nuevoPeso: peso,
      pesosPorSerie: pesosPorSerie,
      nuevaDuracionSegundos: duracion,
      nuevaDistanciaMetros: distancia,
      nuevoTiempoIsometricoSegundos: tiempoIso,
      log: log.isEmpty ? null : log.join(' | '),
    );
  }

  // ---------------------------------------------------------------------------
  // Degradación por inactividad
  // ---------------------------------------------------------------------------

  ProgresionEjercicio degradarPorInactividad({
    required String ejercicioId,
    required int seriesActuales,
    required int repeticionesActuales,
    required int descansoActual,
    required double? pesoActual,
    required List<String> tipoMedicion,
    required int diasInactivo,
    ParametrosObjetivo? params,
    int? duracionActual,
    int? distanciaActual,
    int? tiempoIsometricoActual,
  }) {
    if (diasInactivo <= 14) {
      return ProgresionEjercicio(
        ejercicioId: ejercicioId,
        nuevasSeries: seriesActuales,
        nuevasRepeticiones: repeticionesActuales,
        nuevoDescanso: descansoActual,
        nuevoPeso: pesoActual,
        nuevaDuracionSegundos: duracionActual,
        nuevaDistanciaMetros: distanciaActual,
        nuevoTiempoIsometricoSegundos: tiempoIsometricoActual,
        log: null,
      );
    }

    final factor = (diasInactivo > 21) ? 0.70 : 0.80;
    final usaPeso = tipoMedicion.contains('peso');
    double? peso = pesoActual;
    int series = seriesActuales;
    int? duracion = duracionActual;
    int? distancia = distanciaActual;
    int? tiempoIso = tiempoIsometricoActual;

    if (usaPeso && peso != null) peso = peso * factor;
    if (tipoMedicion.contains('tiempo') &&
        !tipoMedicion.contains('repeticiones') &&
        tiempoIso != null) {
      tiempoIso = (tiempoIso * factor).round();
    }
    if (duracion != null) duracion = (duracion * factor).round();
    if (distancia != null) distancia = (distancia * factor).round();
    if (params != null) {
      series = (series - 1).clamp(params.seriesMin, params.seriesMax);
    }

    return ProgresionEjercicio(
      ejercicioId: ejercicioId,
      nuevasSeries: series,
      nuevasRepeticiones: repeticionesActuales,
      nuevoDescanso: descansoActual + 30,
      nuevoPeso: peso,
      nuevaDuracionSegundos: duracion,
      nuevaDistanciaMetros: distancia,
      nuevoTiempoIsometricoSegundos: tiempoIso,
      log: '$diasInactivo días inactivo → carga ×$factor',
    );
  }

  // ---------------------------------------------------------------------------
  // Generación inicial (sin historial)
  // ---------------------------------------------------------------------------

  ProgresionEjercicio generarInicial({
    required String ejercicioId,
    required int series,
    required int repeticiones,
    required int descanso,
    double? pesoKg,
    required List<String> tipoMedicion,
    int? duracionSegundos,
    int? distanciaMetros,
    int? tiempoIsometricoSegundos,
  }) {
    final usaPeso = tipoMedicion.contains('peso');
    final pesosPorSerie = (usaPeso && pesoKg != null && pesoKg > 0)
        ? generarPesosPorSerie(pesoObjetivo: pesoKg, totalSeries: series)
        : null;

    return ProgresionEjercicio(
      ejercicioId: ejercicioId,
      nuevasSeries: series,
      nuevasRepeticiones: repeticiones,
      nuevoDescanso: descanso,
      nuevoPeso: pesoKg,
      pesosPorSerie: pesosPorSerie,
      nuevaDuracionSegundos: duracionSegundos,
      nuevaDistanciaMetros: distanciaMetros,
      nuevoTiempoIsometricoSegundos: tiempoIsometricoSegundos,
      log: null,
    );
  }

  // ---------------------------------------------------------------------------
  // Batch: aplicar progresión a toda la estructura
  // ---------------------------------------------------------------------------

  Map<int, Map<int, List<EjercicioInput>>> progresionarEstructura({
    required Map<int, Map<int, List<EjercicioInput>>> estructura,
    required Map<String, List<String>> tipoMedicionPorEjercicio,
    Map<String, List<SerieRealizadaDto>> historialPorEjercicio = const {},
    Map<String, double> rpePorEjercicio = const {},
    int diasInactivo = 0,
    ParametrosObjetivo? params,
  }) {
    final resultado = <int, Map<int, List<EjercicioInput>>>{};
    for (final semana in estructura.entries) {
      resultado[semana.key] = {};
      for (final dia in semana.value.entries) {
        resultado[semana.key]![dia.key] = dia.value.map((e) {
          final tipoMed =
              tipoMedicionPorEjercicio[e.ejercicioId] ?? ['repeticiones'];
          final historial = historialPorEjercicio[e.ejercicioId];
          final rpe = rpePorEjercicio[e.ejercicioId];
          ProgresionEjercicio prog;

          if (diasInactivo > 14) {
            prog = degradarPorInactividad(
              ejercicioId: e.ejercicioId,
              seriesActuales: e.series,
              repeticionesActuales: e.repeticiones,
              descansoActual: e.segundosDescanso,
              pesoActual: e.pesoKg,
              tipoMedicion: tipoMed,
              diasInactivo: diasInactivo,
              params: params,
              duracionActual: e.duracionSegundos,
              distanciaActual: e.distanciaMetros,
              tiempoIsometricoActual: e.tiempoIsometricoSegundos,
            );
          } else if (historial != null && rpe != null) {
            prog = calcularProgresion(
              ejercicioId: e.ejercicioId,
              seriesActuales: e.series,
              repeticionesActuales: e.repeticiones,
              descansoActual: e.segundosDescanso,
              pesoActual: e.pesoKg,
              tipoMedicion: tipoMed,
              rpeUltimaSesion: rpe,
              seriesRealizadas: historial,
              params: params,
              duracionActual: e.duracionSegundos,
              distanciaActual: e.distanciaMetros,
              tiempoIsometricoActual: e.tiempoIsometricoSegundos,
            );
          } else {
            prog = generarInicial(
              ejercicioId: e.ejercicioId,
              series: e.series,
              repeticiones: e.repeticiones,
              descanso: e.segundosDescanso,
              pesoKg: e.pesoKg,
              tipoMedicion: tipoMed,
              duracionSegundos: e.duracionSegundos,
              distanciaMetros: e.distanciaMetros,
              tiempoIsometricoSegundos: e.tiempoIsometricoSegundos,
            );
          }

          return EjercicioInput(
            ejercicioId: prog.ejercicioId,
            series: prog.nuevasSeries,
            repeticiones: prog.nuevasRepeticiones,
            segundosDescanso: prog.nuevoDescanso,
            pesoKg: prog.nuevoPeso,
            pesosKg: prog.pesosPorSerie,
            duracionSegundos: prog.nuevaDuracionSegundos ?? e.duracionSegundos,
            distanciaMetros: prog.nuevaDistanciaMetros ?? e.distanciaMetros,
            tiempoIsometricoSegundos: prog.nuevoTiempoIsometricoSegundos ??
                e.tiempoIsometricoSegundos,
          );
        }).toList();
      }
    }
    return resultado;
  }
}
