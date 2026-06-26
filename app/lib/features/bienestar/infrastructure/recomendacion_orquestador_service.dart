import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/models/db_models.dart';
import '../application/ejercicios_provider.dart';
import '../application/rutina_provider.dart';
import '../domain/ejercicio_recomendado_dto.dart';
import '../domain/recomendacion_result_dto.dart';
import 'parametros_objetivo.dart';
import 'recomendacion_contexto_service.dart';
import 'recomendacion_reglas_service.dart';
import 'progresion_calculator.dart';
import 'transicion_objetivo_service.dart';

class MetadatosGeneracion {
  final String objetivo;
  final String split;
  final String? motivoAjustes;
  final double factorCargaTotal;
  final bool iaRefinada;

  const MetadatosGeneracion({
    required this.objetivo,
    required this.split,
    this.motivoAjustes,
    this.factorCargaTotal = 0.0,
    this.iaRefinada = false,
  });
}

class ResultadoGeneracion {
  final String nombre;
  final String descripcion;
  final String objetivo;
  final int duracionSemanas;
  final Map<int, Map<int, List<EjercicioInput>>> estructura;
  final MetadatosGeneracion metadatos;
  final String? error;

  const ResultadoGeneracion({
    required this.nombre,
    required this.descripcion,
    required this.objetivo,
    required this.duracionSemanas,
    required this.estructura,
    required this.metadatos,
    this.error,
  });

  bool get tieneError => error != null;
}

class RecomendacionOrquestadorService {
  final RecomendacionReglasService _reglas = RecomendacionReglasService();
  final RecomendacionContextoService _contexto = RecomendacionContextoService();
  final ProgresionCalculator _progresion = ProgresionCalculator();
  final TransicionObjetivoService _transicion = TransicionObjetivoService();
  final RecomendacionIaService _ia = RecomendacionIaService();

  Future<ResultadoGeneracion> generarRutina({
    required PerfilBienestarDb perfil,
    required List<EjercicioDb> catalogo,
    HistorialSesionDto? historial,
    EstadoDiarioDb? estadoDiario,
    ContextoAcademico? contextoAcademico,
    ContextoFisiologico? contextoFisiologico,
    HistorialObjetivoDb? historialObjetivo,
    Map<String, List<String>>? tipoMedicionCache,
    Map<String, List<SerieRealizadaDto>>? historialSeries,
    Map<String, double>? rpePorEjercicio,
    int diasInactivo = 0,
    int duracionSemanas = 1,
    String? apiKey,
    bool conIA = false,
  }) async {
    // 0. Unificar objetivo
    final obj = sanitizarObjetivo(perfil.objetivoPrincipal);
    var params = ParametrosObjetivo.de(obj);

    // 1. Reglas: selección de ejercicios + split
    var estructura = _reglas.generarEstructura(
      perfil: perfil,
      catalogo: catalogo,
      params: params,
      historial: historial,
    );

    final totalEjercicios = estructura.values.fold<int>(
        0, (s, dias) => s + dias.values.fold<int>(0, (t, ej) => t + ej.length));
    if (totalEjercicios == 0) {
      return ResultadoGeneracion(
        nombre: 'Rutina de $obj',
        descripcion:
            'No se encontraron ejercicios compatibles con tu equipo y nivel. Revisa tu perfil de bienestar.',
        objetivo: obj,
        duracionSemanas: duracionSemanas,
        estructura: estructura,
        metadatos: MetadatosGeneracion(
          objetivo: obj,
          split: _determinarSplitLabel(perfil),
        ),
        error: 'Sin ejercicios compatibles',
      );
    }

    // 2. Contexto: ajustes por academia, fisiología, racha
    String? motivoAjustes;
    double fct = 0.0;
    final ac = contextoAcademico;
    final fi = contextoFisiologico;
    if (ac != null && fi != null) {
      final ajuste = _contexto.calcularAjustes(
        academico: ac,
        fisiologico: fi,
        estadoDiario: estadoDiario,
      );
      fct = ajuste.factorCargaTotal;
      motivoAjustes = ajuste.motivo;

      if (ajuste.factorVolumen != 1.0 ||
          ajuste.deltaSeries != 0 ||
          ajuste.deltaDescanso != 0) {
        estructura = _contexto.aplicarAjustes(
          estructura: estructura,
          ajuste: ajuste,
          params: params,
        );
      }
    }

    // 2.5 Check-in: filtro fino de ejercicios por estado diario
    if (estadoDiario != null) {
      estructura = _contexto.filtrarPorCheckIn(
        estructura: estructura,
        estadoDiario: estadoDiario,
        catalogo: catalogo,
      );
    }

    // 3. Transición de objetivo
    if (historialObjetivo != null) {
      final trans = _transicion.calcularTransicion(
        objetivoActual: obj,
        registroAnterior: historialObjetivo,
      );
      if (trans.motivo != null) {
        motivoAjustes = motivoAjustes != null
            ? '$motivoAjustes | ${trans.motivo}'
            : trans.motivo;
      }
      estructura = _transicion.aplicarTransicion(
        estructura: estructura,
        transicion: trans,
      );
      params = trans.params;
    }

    // 4. Progresión: pesos por serie + cálculos de 1RM
    final tipoMedCache =
        tipoMedicionCache ?? _buildTipoMedicionCache(estructura, catalogo);
    estructura = _progresion.progresionarEstructura(
      estructura: estructura,
      tipoMedicionPorEjercicio: tipoMedCache,
      historialPorEjercicio: historialSeries ?? {},
      rpePorEjercicio: rpePorEjercicio ?? {},
      diasInactivo: diasInactivo,
      params: params,
    );

    // 5. Nombre/descripción contextual
    final splitLabel = _determinarSplitLabel(perfil);
    final nombreBase = _generarNombreRutina(obj, splitLabel, duracionSemanas);
    final descBase = _generarDescripcionRutina(
      obj,
      splitLabel,
      perfil.diasDisponiblesSemana,
      perfil.equipamientoDisponible,
      motivoAjustes,
    );

    // 6. IA opcional
    if (conIA && apiKey != null && apiKey.isNotEmpty) {
      final pesosKgPreIa = _capturarPesosKg(estructura);
      final estructuraPreIa = estructura;
      final baseParaIA = _convertirParaIA(estructura);

      RecomendacionRutinaResult? resultadoIA;
      try {
        resultadoIA = await _ia
            .refinarRutina(
              apiKey: apiKey,
              nombreRutina: nombreBase,
              descripcionRutina: descBase,
              objetivoRutina: obj,
              duracionSemanas: duracionSemanas,
              estructuraBase: baseParaIA,
              perfil: perfil,
              catalogo: catalogo,
              historial: historial,
              estadoDiario: estadoDiario,
              contextoAcademico: contextoAcademico,
              motivoAjustes: motivoAjustes,
            )
            .timeout(const Duration(seconds: 30));
      } on TimeoutException {
        motivoAjustes = motivoAjustes != null
            ? '$motivoAjustes | IA no disponible (timeout)'
            : 'IA no disponible (timeout)';
      } catch (e) {
        debugPrint('[Orquestador] Error en refinamiento IA: $e');
        motivoAjustes = motivoAjustes != null
            ? '$motivoAjustes | IA no disponible'
            : 'IA no disponible';
      }

      if (resultadoIA != null && resultadoIA.tieneError) {
        motivoAjustes = motivoAjustes != null
            ? '$motivoAjustes | IA: ${resultadoIA.error}'
            : 'IA: ${resultadoIA.error}';
      }

      if (resultadoIA != null && !resultadoIA.tieneError) {
        estructura = _convertirDesdeIA(resultadoIA.estructura);
        estructura =
            _preservarParamsPreIa(estructura, pesosKgPreIa, estructuraPreIa);

        return ResultadoGeneracion(
          nombre: resultadoIA.nombre,
          descripcion: resultadoIA.descripcion,
          objetivo: obj,
          duracionSemanas: duracionSemanas,
          estructura: estructura,
          metadatos: MetadatosGeneracion(
            objetivo: obj,
            split: _determinarSplitLabel(perfil),
            motivoAjustes: motivoAjustes,
            factorCargaTotal: fct,
            iaRefinada: true,
          ),
        );
      }
    }

    return ResultadoGeneracion(
      nombre: nombreBase,
      descripcion: descBase,
      objetivo: obj,
      duracionSemanas: duracionSemanas,
      estructura: estructura,
      metadatos: MetadatosGeneracion(
        objetivo: obj,
        split: _determinarSplitLabel(perfil),
        motivoAjustes: motivoAjustes,
        factorCargaTotal: fct,
        iaRefinada: false,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, List<String>> _buildTipoMedicionCache(
      Map<int, Map<int, List<EjercicioInput>>> estructura,
      List<EjercicioDb> catalogo) {
    final cache = <String, List<String>>{};
    for (final s in estructura.values) {
      for (final d in s.values) {
        for (final e in d) {
          if (!cache.containsKey(e.ejercicioId)) {
            final match = catalogo.cast<EjercicioDb?>().firstWhere(
                  (ex) => ex?.id == e.ejercicioId,
                  orElse: () => null,
                );
            cache[e.ejercicioId] = match?.tipoMedicion ?? ['repeticiones'];
          }
        }
      }
    }
    return cache;
  }

  Map<int, Map<int, List<EjercicioRecomendado>>> _convertirParaIA(
      Map<int, Map<int, List<EjercicioInput>>> estructura) {
    final result = <int, Map<int, List<EjercicioRecomendado>>>{};
    for (final s in estructura.entries) {
      result[s.key] = {};
      for (final d in s.value.entries) {
        result[s.key]![d.key] = d.value
            .map((e) => EjercicioRecomendado(
                  ejercicioId: e.ejercicioId,
                  series: e.series,
                  repeticiones: e.repeticiones,
                  segundosDescanso: e.segundosDescanso,
                  pesoKg: e.pesoKg,
                  duracionObjetivoSegundos: e.duracionObjetivoSegundos,
                  distanciaMetros: e.distanciaMetros,
                  tiempoIsometricoSegundos: e.tiempoIsometricoSegundos,
                ))
            .toList();
      }
    }
    return result;
  }

  Map<int, Map<int, List<EjercicioInput>>> _convertirDesdeIA(
      Map<int, Map<int, List<EjercicioRecomendado>>> estructura) {
    final result = <int, Map<int, List<EjercicioInput>>>{};
    for (final s in estructura.entries) {
      result[s.key] = {};
      for (final d in s.value.entries) {
        result[s.key]![d.key] = d.value
            .map((e) => EjercicioInput(
                  ejercicioId: e.ejercicioId,
                  series: e.series,
                  repeticiones: e.repeticiones,
                  segundosDescanso: e.segundosDescanso,
                  pesoKg: e.pesoKg,
                  duracionObjetivoSegundos: e.duracionObjetivoSegundos,
                  distanciaMetros: e.distanciaMetros,
                  tiempoIsometricoSegundos: e.tiempoIsometricoSegundos,
                ))
            .toList();
      }
    }
    return result;
  }

  String _determinarSplitLabel(PerfilBienestarDb perfil) {
    return _reglas.splitLabel(
        perfil.diasDisponiblesSemana, perfil.nivelActividad);
  }

  String _generarNombreRutina(String obj, String splitLabel, int semanas) {
    return '$obj · $splitLabel · $semanas semanas';
  }

  String _generarDescripcionRutina(
    String obj,
    String splitLabel,
    int dias,
    List<String> equipamiento,
    String? motivoAjustes,
  ) {
    final buffer = StringBuffer();
    buffer.write('Rutina de ${obj.toLowerCase()} con split $splitLabel');
    buffer.write(' para $dias días por semana.');
    if (equipamiento.isNotEmpty) {
      buffer.write(' Equipamiento: ${equipamiento.take(3).join(', ')}.');
    }
    if (motivoAjustes != null) {
      buffer.write(' Adaptada: $motivoAjustes.');
    }
    return buffer.toString();
  }

  Map<String, Map<int, List<double>?>> _capturarPesosKg(
      Map<int, Map<int, List<EjercicioInput>>> estructura) {
    final result = <String, Map<int, List<double>?>>{};
    for (final s in estructura.entries) {
      for (final d in s.value.entries) {
        for (var i = 0; i < d.value.length; i++) {
          final e = d.value[i];
          if (e.pesosKg != null) {
            result.putIfAbsent(e.ejercicioId, () => {})[d.key * 100 + i] =
                e.pesosKg;
          }
        }
      }
    }
    return result;
  }

  Map<int, Map<int, List<EjercicioInput>>> _preservarParamsPreIa(
    Map<int, Map<int, List<EjercicioInput>>> estructura,
    Map<String, Map<int, List<double>?>> pesosKgPrevios,
    Map<int, Map<int, List<EjercicioInput>>> estructuraPreIa,
  ) {
    final result = <int, Map<int, List<EjercicioInput>>>{};
    for (final s in estructura.entries) {
      result[s.key] = {};
      for (final d in s.value.entries) {
        result[s.key]![d.key] = d.value.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final key = d.key * 100 + i;
          final previos = pesosKgPrevios[e.ejercicioId];
          final prevPesos = previos != null && previos.containsKey(key)
              ? previos[key]
              : e.pesosKg;

          final preIa = estructuraPreIa[s.key]?[d.key]?.elementAtOrNull(i);

          return EjercicioInput(
            ejercicioId: e.ejercicioId,
            series: e.series,
            repeticiones: e.repeticiones,
            segundosDescanso: e.segundosDescanso,
            pesoKg: e.pesoKg,
            pesosKg: prevPesos,
            duracionObjetivoSegundos:
                e.duracionObjetivoSegundos ?? preIa?.duracionObjetivoSegundos,
            distanciaMetros: e.distanciaMetros ?? preIa?.distanciaMetros,
            tiempoIsometricoSegundos:
                e.tiempoIsometricoSegundos ?? preIa?.tiempoIsometricoSegundos,
          );
        }).toList();
      }
    }
    return result;
  }
}
