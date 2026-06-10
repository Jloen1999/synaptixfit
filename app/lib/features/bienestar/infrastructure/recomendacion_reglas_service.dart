import 'dart:math';

import '../../../shared/models/db_models.dart';
import '../application/rutina_provider.dart';
import 'parametros_objetivo.dart';
import 'recomendacion_ia_service.dart';

enum TipoSplit { fullBody, upperLower, pushPullLegs }

class DiaMusculos {
  final int dia;
  final List<String> musculosObjetivo;
  final List<String> partesCuerpo;

  const DiaMusculos(this.dia, this.musculosObjetivo, this.partesCuerpo);
}

class RecomendacionReglasService {
  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Map<int, Map<int, List<EjercicioInput>>> generarEstructura({
    required PerfilBienestarDb perfil,
    required List<EjercicioDb> catalogo,
    required ParametrosObjetivo params,
    HistorialSesionDto? historial,
  }) {
    final paramsBio = _ajustarParamsPorBiometria(params, perfil);
    final split =
        determinarSplit(perfil.diasDisponiblesSemana, perfil.nivelActividad);
    final diasMusculos = _musculosPorDia(split, perfil.diasDisponiblesSemana);

    final estructura = <int, Map<int, List<EjercicioInput>>>{};
    estructura[1] = {};

    for (final dm in diasMusculos) {
      var pool = _aplicarFiltros(catalogo, perfil, paramsBio, dm, historial);
      pool = _scoreOrdenar(pool, paramsBio, perfil);
      var seleccionados = _seleccionBalanceada(pool, paramsBio, dm, perfil);
      seleccionados =
          _aplicarAjustesBio(seleccionados, perfil, paramsBio, catalogo, dm);
      estructura[1]![dm.dia] = seleccionados;
    }

    return estructura;
  }

  // ---------------------------------------------------------------------------
  // 1. Split determination
  // ---------------------------------------------------------------------------

  TipoSplit determinarSplit(int diasSemana, String nivelActividad) {
    final nivel = _nivelNumerico(nivelActividad);

    if (diasSemana >= 5) return TipoSplit.pushPullLegs;
    if (diasSemana >= 4 && nivel >= 2) return TipoSplit.upperLower;
    return TipoSplit.fullBody;
  }

  String splitLabel(int diasSemana, String nivelActividad) {
    switch (determinarSplit(diasSemana, nivelActividad)) {
      case TipoSplit.pushPullLegs:
        return 'Push/Pull/Legs';
      case TipoSplit.upperLower:
        return 'Upper/Lower';
      case TipoSplit.fullBody:
        return 'Full-Body';
    }
  }

  String generarNombreDia(DiaMusculos dm) {
    final musculos = dm.musculosObjetivo.map((m) => m.toLowerCase()).toSet();
    final tienePush = musculos.any((m) =>
        m.contains('pectoral') ||
        m.contains('deltoides anterior') ||
        m.contains('deltoides medio') ||
        m.contains('tríceps'));
    final tienePull = musculos.any((m) =>
        m.contains('dorsal') ||
        m.contains('bíceps') ||
        m.contains('romboides') ||
        m.contains('trapecio'));
    final tienePierna = musculos.any((m) =>
        m.contains('cuádriceps') ||
        m.contains('isquiotibiales') ||
        m.contains('glúteo'));

    if (tienePush && tienePull && tienePierna) {
      return 'D${dm.dia} · Full-Body';
    }
    if (tienePush && !tienePull && !tienePierna) {
      return 'D${dm.dia} · Empuje';
    }
    if (!tienePush && tienePull && !tienePierna) {
      return 'D${dm.dia} · Tracción';
    }
    if (!tienePush && !tienePull && tienePierna) {
      return 'D${dm.dia} · Pierna';
    }

    final categorias = <String>[];
    if (tienePush) categorias.add('Empuje');
    if (tienePull) categorias.add('Tracción');
    if (tienePierna) categorias.add('Pierna');
    return 'D${dm.dia} · ${categorias.join(' + ')}';
  }

  String generarNombreSemana(TipoSplit split, int semana, int totalSemanas) {
    final splitName = (() {
      switch (split) {
        case TipoSplit.pushPullLegs:
          return 'Push/Pull/Legs';
        case TipoSplit.upperLower:
          return 'Upper/Lower';
        case TipoSplit.fullBody:
          return 'Cuerpo Completo';
      }
    })();

    final fase = _faseSemana(semana, totalSemanas);
    return 'S$semana · $fase — $splitName';
  }

  String _faseSemana(int semana, int totalSemanas) {
    if (semana == 1) return 'Adaptación';
    if (semana == totalSemanas && totalSemanas >= 4) return 'Peak';
    final tercio = totalSemanas / 3;
    if (semana <= tercio.ceil()) return 'Carga';
    if (semana <= (tercio * 2).ceil()) return 'Sobrecarga';
    return 'Especialización';
  }

  int _nivelNumerico(String nivelActividad) {
    switch (nivelActividad) {
      case 'sedentario':
        return 0;
      case 'ligero':
        return 1;
      case 'moderado':
        return 2;
      case 'alto':
        return 3;
      default:
        return 1;
    }
  }

  ParametrosObjetivo _ajustarParamsPorBiometria(
      ParametrosObjetivo params, PerfilBienestarDb perfil) {
    var intensidadRelativa = params.intensidadRelativa;
    var repsMin = params.repsMin;
    var repsMax = params.repsMax;

    if (perfil.imc > 30) {
      intensidadRelativa = min(intensidadRelativa, 0.65);
    }
    if (perfil.edad > 50) {
      intensidadRelativa = min(intensidadRelativa, 0.70);
      repsMin = max(repsMin, 8);
      repsMax = max(repsMax, repsMin);
    }
    if (perfil.edad < 18) {
      intensidadRelativa = min(intensidadRelativa, 0.75);
    }

    return ParametrosObjetivo(
      objetivo: params.objetivo,
      seriesMin: params.seriesMin,
      seriesMax: params.seriesMax,
      repsMin: repsMin,
      repsMax: repsMax,
      descansoMin: params.descansoMin,
      descansoMax: params.descansoMax,
      rpeMin: params.rpeMin,
      rpeMax: params.rpeMax,
      intensidadRelativa: intensidadRelativa,
      ejerciciosPorDia: params.ejerciciosPorDia,
      priorizarCompuestos: params.priorizarCompuestos,
      modalidades: params.modalidades,
      finalidadesEjercicio: params.finalidadesEjercicio,
      volumenSemanalObjetivo: params.volumenSemanalObjetivo,
      admiteCircuito: params.admiteCircuito,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Muscle assignment per day
  // ---------------------------------------------------------------------------

  List<DiaMusculos> _musculosPorDia(TipoSplit split, int totalDias) {
    switch (split) {
      case TipoSplit.fullBody:
        return _generarFullBody(totalDias);
      case TipoSplit.upperLower:
        return _generarUpperLower(totalDias);
      case TipoSplit.pushPullLegs:
        return _generarPushPullLegs(totalDias);
    }
  }

  List<DiaMusculos> _generarFullBody(int totalDias) {
    return List.generate(totalDias, (i) {
      return DiaMusculos(i + 1, _todosMusculos(), _todasPartes());
    });
  }

  List<DiaMusculos> _generarUpperLower(int totalDias) {
    final dias = <DiaMusculos>[];
    for (var d = 0; d < totalDias; d++) {
      if (d.isEven) {
        dias.add(DiaMusculos(d + 1, _musculosUpper(), _partesUpper()));
      } else {
        dias.add(DiaMusculos(d + 1, _musculosLower(), _partesLower()));
      }
    }
    return dias;
  }

  List<DiaMusculos> _generarPushPullLegs(int totalDias) {
    final secuencia = [
      DiaMusculos(1, _musculosPush(), _partesPush()),
      DiaMusculos(2, _musculosPull(), _partesPull()),
      DiaMusculos(3, _musculosLower(), _partesLower()),
    ];
    final dias = <DiaMusculos>[];
    for (var d = 0; d < totalDias; d++) {
      dias.add(DiaMusculos(d + 1, secuencia[d % 3].musculosObjetivo,
          secuencia[d % 3].partesCuerpo));
    }
    return dias;
  }

  // ---- Muscle lists (matching dataset values) ----

  static List<String> _todosMusculos() => [
        'Pectoral mayor',
        'Deltoides anterior',
        'Deltoides medio',
        'Tríceps braquial',
        'Dorsal ancho',
        'Romboides',
        'Bíceps braquial',
        'Cuádriceps',
        'Isquiotibiales',
        'Glúteo mayor',
        'Recto abdominal',
        'Oblicuos',
        'Erectores espinales',
      ];

  static List<String> _todasPartes() => [
        'Tren superior',
        'Tren inferior',
        'Core',
        'Zona media',
        'Cuerpo completo',
      ];

  static List<String> _musculosUpper() => [
        'Pectoral mayor',
        'Deltoides anterior',
        'Deltoides medio',
        'Deltoides posterior',
        'Tríceps braquial',
        'Dorsal ancho',
        'Romboides',
        'Bíceps braquial',
        'Trapecio superior',
        'Braquial',
        'Braquiorradial',
      ];

  static List<String> _partesUpper() => [
        'Tren superior',
        'Pecho',
        'Hombros',
        'Espalda',
        'Espalda alta',
        'Brazos',
      ];

  static List<String> _musculosLower() => [
        'Cuádriceps',
        'Isquiotibiales',
        'Glúteo mayor',
        'Recto abdominal',
        'Oblicuos',
        'Erectores espinales',
      ];

  static List<String> _partesLower() => [
        'Tren inferior',
        'Piernas',
        'Cadera',
        'Caderas',
        'Core',
        'Zona media',
      ];

  static List<String> _musculosPush() => [
        'Pectoral mayor',
        'Deltoides anterior',
        'Deltoides medio',
        'Tríceps braquial',
      ];

  static List<String> _partesPush() => [
        'Tren superior',
        'Pecho',
        'Hombros',
        'Brazos',
      ];

  static List<String> _musculosPull() => [
        'Dorsal ancho',
        'Romboides',
        'Deltoides posterior',
        'Bíceps braquial',
        'Trapecio superior',
        'Braquial',
      ];

  static List<String> _partesPull() => [
        'Tren superior',
        'Espalda',
        'Espalda alta',
        'Brazos',
        'Hombros',
      ];

  // ---------------------------------------------------------------------------
  // 3. Filters
  // ---------------------------------------------------------------------------

  List<EjercicioDb> _aplicarFiltros(
    List<EjercicioDb> catalogo,
    PerfilBienestarDb perfil,
    ParametrosObjetivo params,
    DiaMusculos dm,
    HistorialSesionDto? historial,
  ) {
    final nombresRecientes = historial?.ejerciciosRecientes
            .map((e) => e.nombreEjercicio.toLowerCase())
            .toSet() ??
        {};

    return catalogo.where((e) {
      if (!_dificultadApta(e.dificultad, perfil.nivelActividad)) return false;
      if (!_equipamientoCompatible(e, perfil)) return false;
      if (!_modalidadMatch(e, params)) return false;
      if (!_musculoMatch(e, dm)) return false;
      if (nombresRecientes.contains(e.nombre.toLowerCase())) return false;
      if (!_ejercicioAptoBiometria(e, perfil)) return false;
      return true;
    }).toList();
  }

  bool _dificultadApta(String dificultad, String nivelActividad) {
    final nivel = _nivelNumerico(nivelActividad);
    switch (dificultad) {
      case 'principiante':
        return true;
      case 'intermedio':
        return nivel >= 1;
      case 'avanzado':
        return nivel >= 2;
      default:
        return true;
    }
  }

  bool _equipamientoCompatible(
      EjercicioDb ejercicio, PerfilBienestarDb perfil) {
    final userEquip = perfil.equipamientoDisponible
        .map((e) => e.toLowerCase().trim().replaceAll('_', ' '))
        .toSet();
    if (userEquip.contains('sin equipamiento') ||
        userEquip.contains('peso corporal') ||
        userEquip.contains('peso_corporal')) {
      return true;
    }
    if (ejercicio.equipamientos.isEmpty) return true;
    return ejercicio.equipamientos.every((req) {
      final r = req.toLowerCase().trim();
      return userEquip.contains(r) || r == 'suelo' || r == 'asistencia';
    });
  }

  bool _modalidadMatch(EjercicioDb ejercicio, ParametrosObjetivo params) {
    return params.modalidades.contains(ejercicio.modalidadEntrenamiento);
  }

  bool _musculoMatch(EjercicioDb ejercicio, DiaMusculos dm) {
    final musculosEj =
        ejercicio.musculosObjetivo.map((m) => m.toLowerCase()).toSet();
    final musculosDia = dm.musculosObjetivo.map((m) => m.toLowerCase()).toSet();
    return musculosEj.intersection(musculosDia).isNotEmpty;
  }

  static const _keywordsAltoImpacto = [
    'salto',
    'saltar',
    'saltos',
    'saltando',
    'pliométrico',
    'pliometrico',
    'plyometric',
    'plyo',
    'burpee',
    'burpees',
    'box jump',
    'tuck jump',
    'broad jump',
    'depth jump',
    'squat jump',
  ];

  bool _ejercicioAptoBiometria(
      EjercicioDb ejercicio, PerfilBienestarDb perfil) {
    if (perfil.imc > 30) {
      final partesPierna = ejercicio.partesCuerpo.any((p) {
        final pl = p.toLowerCase();
        return pl.contains('pierna') || pl.contains('tren inferior');
      });
      if (partesPierna) {
        final nombreLower = ejercicio.nombre.toLowerCase();
        final esAltoImpacto =
            _keywordsAltoImpacto.any((kw) => nombreLower.contains(kw));
        if (esAltoImpacto) return false;
      }
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // 4. Scoring
  // ---------------------------------------------------------------------------

  List<EjercicioDb> _scoreOrdenar(
      List<EjercicioDb> pool, ParametrosObjetivo params,
      [PerfilBienestarDb? perfil]) {
    final scored =
        pool.map((e) => (e, _scoreEjercicioParaObjetivo(e, params, perfil)));
    final sorted = scored.toList()..sort((a, b) => b.$2.compareTo(a.$2));
    return sorted.map((s) => s.$1).toList();
  }

  double _scoreEjercicioParaObjetivo(EjercicioDb ej, ParametrosObjetivo params,
      [PerfilBienestarDb? perfil]) {
    double score = 0.0;

    final finalidadesEj = ej.finalidad.map((f) => f.toLowerCase()).toSet();
    final finalidadesObj =
        params.finalidadesEjercicio.map((f) => f.toLowerCase()).toSet();
    final matchesFinalidad = finalidadesEj.intersection(finalidadesObj).length;
    if (ej.finalidad.isNotEmpty) {
      score += (matchesFinalidad / ej.finalidad.length) * 0.40;
    }

    if (params.priorizarCompuestos && ej.musculosSecundarios.length >= 2) {
      score += 0.25;
    }

    score += _scoreDificultad(ej.dificultad, params.objetivo) * 0.20;

    if (ej.finalidad.length >= 2) score += 0.10;
    if (ej.finalidad.length >= 3) score += 0.05;

    if (perfil != null) {
      if (perfil.imc < 18.5 &&
          ej.finalidad.any((f) => f.toLowerCase() == 'hipertrofia muscular')) {
        score += 0.10;
      }
      if (perfil.edad < 18 &&
          ej.equipamientos
              .any((eq) => eq.toLowerCase().contains('peso corporal'))) {
        score += 0.15;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  double _scoreDificultad(String dificultad, String objetivo) {
    switch (objetivo) {
      case 'Fuerza Máxima':
      case 'Potencia y Explosividad':
        return dificultad == 'avanzado'
            ? 1.0
            : dificultad == 'intermedio'
                ? 0.4
                : 0.0;
      case 'Movilidad y Flexibilidad':
      case 'Estabilidad y Control Motor':
        return dificultad == 'principiante'
            ? 1.0
            : dificultad == 'intermedio'
                ? 0.6
                : 0.3;
      default:
        return dificultad == 'intermedio'
            ? 1.0
            : dificultad == 'principiante'
                ? 0.5
                : 0.7;
    }
  }

  // ---------------------------------------------------------------------------
  // 5. Balanced selection
  // ---------------------------------------------------------------------------

  List<EjercicioInput> _seleccionBalanceada(
    List<EjercicioDb> pool,
    ParametrosObjetivo params,
    DiaMusculos dm,
    PerfilBienestarDb perfil,
  ) {
    final compuestos = <EjercicioDb>[];
    final aislados = <EjercicioDb>[];
    for (final e in pool) {
      if (e.musculosSecundarios.length >= 2 && e.musculosObjetivo.length <= 2) {
        compuestos.add(e);
      } else {
        aislados.add(e);
      }
    }

    final seleccionados = <EjercicioDb>[];
    final usedPrimaries = <String>{};

    int tomados = 0;
    final maxCompuestos = (params.ejerciciosPorDia * 0.6).ceil();
    for (final e in compuestos) {
      if (tomados >= maxCompuestos) break;
      final primary = e.musculosObjetivo.isNotEmpty
          ? e.musculosObjetivo.first.toLowerCase()
          : '';
      if (primary.isNotEmpty && usedPrimaries.contains(primary)) continue;
      seleccionados.add(e);
      usedPrimaries.add(primary);
      tomados++;
    }

    for (final e in aislados) {
      if (seleccionados.length >= params.ejerciciosPorDia) break;
      final primary = e.musculosObjetivo.isNotEmpty
          ? e.musculosObjetivo.first.toLowerCase()
          : '';
      if (primary.isNotEmpty && usedPrimaries.contains(primary)) continue;
      seleccionados.add(e);
      usedPrimaries.add(primary);
    }

    final allCompounds = [...compuestos, ...aislados];
    for (final e in allCompounds) {
      if (seleccionados.length >= params.ejerciciosPorDia) break;
      if (seleccionados.contains(e)) continue;
      seleccionados.add(e);
    }

    return seleccionados
        .take(params.ejerciciosPorDia)
        .map((e) => _toInput(e, params, perfil))
        .toList();
  }

  List<EjercicioInput> _aplicarAjustesBio(
    List<EjercicioInput> seleccionados,
    PerfilBienestarDb perfil,
    ParametrosObjetivo params,
    List<EjercicioDb> catalogo,
    DiaMusculos dm,
  ) {
    var result = [...seleccionados];

    if (perfil.imc < 18.5) {
      result = result.map((e) {
        final original = catalogo.cast<EjercicioDb?>().firstWhere(
              (ex) => ex?.id == e.ejercicioId,
              orElse: () => null,
            );
        final esCompuesto =
            original != null && original.musculosSecundarios.length >= 2;
        if (esCompuesto) {
          return EjercicioInput(
            ejercicioId: e.ejercicioId,
            series: e.series + 1,
            repeticiones: e.repeticiones,
            segundosDescanso: e.segundosDescanso,
            pesoKg: e.pesoKg,
            pesosKg: e.pesosKg,
            duracionSegundos: e.duracionSegundos,
            distanciaMetros: e.distanciaMetros,
            tiempoIsometricoSegundos: e.tiempoIsometricoSegundos,
          );
        }
        return e;
      }).toList();
    }

    if (perfil.edad > 50) {
      final tieneMovilidad = result.any((e) {
        final original = catalogo.cast<EjercicioDb?>().firstWhere(
              (ex) => ex?.id == e.ejercicioId,
              orElse: () => null,
            );
        return original?.modalidadEntrenamiento == 'movilidad';
      });

      if (!tieneMovilidad && result.length < params.ejerciciosPorDia + 1) {
        final movilidadPool = catalogo.where((e) =>
            e.modalidadEntrenamiento == 'movilidad' &&
            _musculoMatch(e, dm) &&
            _dificultadApta(e.dificultad, perfil.nivelActividad) &&
            _equipamientoCompatible(e, perfil) &&
            _ejercicioAptoBiometria(e, perfil));
        if (movilidadPool.isNotEmpty) {
          final elegido = movilidadPool.first;
          result.add(EjercicioInput(
            ejercicioId: elegido.id,
            series: params.seriesDefault,
            repeticiones: params.repsDefault,
            segundosDescanso: params.descansoDefault,
            pesoKg: null,
            duracionSegundos:
                elegido.tipoMedicion.contains('tiempo') ? 600 : null,
            distanciaMetros:
                elegido.tipoMedicion.contains('distancia') ? 1000 : null,
            tiempoIsometricoSegundos: elegido.tipoMedicion.contains('tiempo') &&
                    !elegido.tipoMedicion.contains('repeticiones')
                ? 30
                : null,
          ));
        }
      }
    }

    return result;
  }

  EjercicioInput _toInput(EjercicioDb ejercicio, ParametrosObjetivo params,
      PerfilBienestarDb perfil) {
    final nivel = _nivelNumerico(perfil.nivelActividad);
    final minPorSesion = perfil.minutosPorSesion;
    final ejerciciosPorDia = params.ejerciciosPorDia;
    final usaTiempo = ejercicio.tipoMedicion.contains('tiempo');
    final usaDistancia = ejercicio.tipoMedicion.contains('distancia');
    final esIsometrico =
        usaTiempo && !ejercicio.tipoMedicion.contains('repeticiones');
    final usaPeso = ejercicio.tipoMedicion.contains('peso') ||
        ejercicio.modalidadEntrenamiento == 'fuerza';

    final timePerExerciseSec =
        ejerciciosPorDia > 0 ? (minPorSesion * 60) ~/ ejerciciosPorDia : 600;
    final nivelFactor = 0.6 + nivel * 0.15;

    int? duracionSegundos;
    if (usaTiempo && !esIsometrico) {
      duracionSegundos =
          (timePerExerciseSec * 0.35 * nivelFactor).round().clamp(120, 3600);
    }

    int? distanciaMetros;
    if (usaDistancia) {
      distanciaMetros =
          ((500 + nivel * 500) * nivelFactor).round().clamp(200, 10000);
    }

    int? tiempoIsometrico;
    if (esIsometrico) {
      tiempoIsometrico = (15 + nivel * 15).clamp(10, 120);
    }

    double? pesoKg;
    if (usaPeso && perfil.pesoKg > 0) {
      final bodyPct = _pesoCorporalEstimado(ejercicio.nombre);
      pesoKg = (perfil.pesoKg * bodyPct * params.intensidadRelativa)
          .clamp(1.0, 300.0);
    }

    return EjercicioInput(
      ejercicioId: ejercicio.id,
      series: params.seriesDefault,
      repeticiones: params.repsDefault,
      segundosDescanso: params.descansoDefault,
      pesoKg: pesoKg,
      duracionSegundos: duracionSegundos,
      distanciaMetros: distanciaMetros,
      tiempoIsometricoSegundos: tiempoIsometrico,
    );
  }

  double _pesoCorporalEstimado(String nombreEjercicio) {
    final n = nombreEjercicio.toLowerCase();
    if (n.contains('sentadilla') || n.contains('squat')) return 0.50;
    if (n.contains('peso muerto') || n.contains('deadlift')) return 0.60;
    if (n.contains('press banca') || n.contains('bench press')) return 0.35;
    if (n.contains('dominada') || n.contains('pull up')) return 0.80;
    if (n.contains('remo') || n.contains('row')) return 0.30;
    if (n.contains('press militar') || n.contains('overhead press')) {
      return 0.25;
    }
    if (n.contains('curl') || n.contains('biceps')) return 0.10;
    if (n.contains('extensión') || n.contains('triceps')) return 0.10;
    if (n.contains('elevación') || n.contains('lateral')) return 0.05;
    return 0.15;
  }
}
