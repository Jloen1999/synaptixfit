import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../shared/models/db_models.dart';

// =============================================================================
// DTOs
// =============================================================================

class EjercicioRecomendado {
  const EjercicioRecomendado({
    required this.ejercicioId,
    this.series = 3,
    this.repeticiones = 10,
    this.segundosDescanso = 90,
    this.pesoKg,
  });

  final String ejercicioId;
  final int series;
  final int repeticiones;
  final int segundosDescanso;
  final double? pesoKg;

  factory EjercicioRecomendado.fromMap(Map<String, dynamic> map) {
    return EjercicioRecomendado(
      ejercicioId: map['exerciseId'] as String? ?? '',
      series: (map['series'] as num?)?.toInt() ?? 3,
      repeticiones: (map['repeticiones'] as num?)?.toInt() ?? 10,
      segundosDescanso: (map['segundosDescanso'] as num?)?.toInt() ?? 90,
      pesoKg: (map['pesoKg'] as num?)?.toDouble(),
    );
  }
}

class RecomendacionRutinaResult {
  const RecomendacionRutinaResult({
    required this.nombre,
    required this.descripcion,
    required this.objetivo,
    required this.duracionSemanas,
    required this.estructura,
    this.error,
  });

  final String nombre;
  final String descripcion;
  final String objetivo;
  final int duracionSemanas;
  final Map<int, Map<int, List<EjercicioRecomendado>>> estructura;
  final String? error;

  bool get tieneError => error != null;
}

class RecomendacionEjerciciosResult {
  const RecomendacionEjerciciosResult({
    required this.ejercicios,
    this.error,
  });

  final List<EjercicioRecomendado> ejercicios;
  final String? error;

  bool get tieneError => error != null;
}

/// Datos de sesiones previas para que la IA pueda aplicar sobrecarga
/// progresiva y detectar patrones de fatiga.
class HistorialSesionDto {
  const HistorialSesionDto({
    this.totalSesionesCompletadas = 0,
    this.rpePromedio = 0.0,
    this.volumenSemanalEstimado = 0,
    this.ejerciciosRecientes = const [],
    this.diasCompletadosUltimaSemana = 0,
    this.semanasConsecutivasEntrenando = 0,
  });

  final int totalSesionesCompletadas;
  final double rpePromedio;
  final int volumenSemanalEstimado;
  final List<EjericicioRecienteDto> ejerciciosRecientes;
  final int diasCompletadosUltimaSemana;
  final int semanasConsecutivasEntrenando;

  bool get requiereDescarga =>
      rpePromedio > 8.0 && semanasConsecutivasEntrenando >= 4;
}

class EjericicioRecienteDto {
  const EjericicioRecienteDto({
    required this.nombreEjercicio,
    required this.pesoPromedio,
    required this.repsPromedio,
    required this.rpePromedio,
    required this.ultimaFecha,
  });

  final String nombreEjercicio;
  final double pesoPromedio;
  final int repsPromedio;
  final double rpePromedio;
  final DateTime ultimaFecha;
}

// =============================================================================
// Servicio
// =============================================================================

class RecomendacionIaService {
  RecomendacionIaService([Dio? dio]) : _dio = dio ?? Dio();

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // 1) Recomendación de metadatos de rutina
  // ---------------------------------------------------------------------------

  Future<RecomendacionRutinaResult> generarRecomendacionRutina({
    required String apiKey,
    required PerfilBienestarDb perfil,
    required List<EjercicioDb> ejerciciosDisponibles,
    HistorialSesionDto? historial,
    EstadoDiarioDb? estadoDiario,
  }) async {
    if (apiKey.trim().isEmpty) {
      return RecomendacionRutinaResult(
        nombre: '',
        descripcion: '',
        objetivo: 'fuerza',
        duracionSemanas: 4,
        estructura: const {},
        error: 'Falta GEMINI_API_KEY en el archivo .env',
      );
    }

    final equipamiento = perfil.equipamientoDisponible;
    final ejerciciosFiltrados = ejerciciosDisponibles
        .where((e) => _ejercicioUsaEquipamiento(e, equipamiento))
        .toList();

    if (ejerciciosFiltrados.isEmpty) {
      return RecomendacionRutinaResult(
        nombre: '',
        descripcion: '',
        objetivo: perfil.objetivoPrincipal,
        duracionSemanas: 4,
        estructura: const {},
        error:
            'No hay ejercicios compatibles con tu equipamiento (${equipamiento.join(", ")}).',
      );
    }

    final historialTxt = _formatearHistorial(historial);
    final estadoTxt = _formatearEstadoDiario(estadoDiario);
    final seguridadIMC = _reglasSeguridadIMC(perfil.imc, perfil.edad);

    final prompt = '''
Eres un entrenador personal profesional con amplia experiencia en prescripcion de ejercicio.
Recomienda los metadatos de una rutina de entrenamiento basada en el perfil del usuario.
Responde UNICAMENTE con un JSON valido. No uses Markdown ni bloques de codigo.

CONTEXTO DEL USUARIO:
- Objetivo principal: ${perfil.objetivoPrincipal}
- Nivel de actividad: ${perfil.nivelActividad}
- Equipamiento disponible (SOLO esto): ${equipamiento.join(', ')}
- Dias disponibles por semana: ${perfil.diasDisponiblesSemana}
- Minutos por sesion: ${perfil.minutosPorSesion}
- Biometria: Edad ${perfil.edad}, Sexo ${perfil.sexo}, Peso ${perfil.pesoKg} kg, Altura ${perfil.alturaCm} cm, IMC ${perfil.imc.toStringAsFixed(1)} (${perfil.imcCategoria})
$historialTxt
$estadoTxt

REGLAS DE SEGURIDAD SEGUN BIOMETRIA (obligatorio cumplir):
$seguridadIMC

REGLAS DE EQUIPAMIENTO (obligatorio):
- SOLO puedes recomendar ejercicios que usen el equipamiento listado arriba.
- Si el usuario solo tiene "peso_corporal", NO recomiendes ejercicios con barra, mancuerna o maquina.
- Revisa el campo "equipamientos" del catalogo para asegurar compatibilidad.

HISTORIAL DEPORTIVO (si existe):
$historialTxt

REGLAS DE RECOMENDACION SEGUN OBJETIVO:
- perder_peso: circuitos, altas repeticiones (15-20), poco descanso (45-60s), peso moderado, ejercicios compuestos
- ganar_masa: rangos de hipertrofia (8-12 reps), descanso 60-90s, ejercicios compuestos y aislados, peso moderado-alto
- fuerza: bajas repeticiones (3-6), descanso largo (120-180s), ejercicios compuestos prioritarios, peso alto
- resistencia: altas repeticiones (15-25), descanso corto (30-45s), peso bajo-moderado
- movilidad: ejercicios de rango completo, peso corporal o ligero, enfasis en tecnica
- fitness_general: equilibrio entre fuerza e hipertrofia (10-12 reps), descanso 60-90s

PERIODIZACION (las semanas se etiquetan automaticamente):
- Semana 1: ADAPTACION (70% volumen, enfasis en tecnica y aprendizaje)
- Semanas intermedias: CARGA PROGRESIVA (85-90% volumen, aumentar peso/reps)
${'Si la rutina dura 4+ semanas, la ultima semana es DESCARGA ACTIVA (60% volumen, recuperacion). Esto es obligatorio para prevenir sobre-entrenamiento.'}
${historial != null && historial.requiereDescarga ? '- ATENCION: El usuario muestra signos de fatiga (RPE promedio ${historial.rpePromedio.toStringAsFixed(1)}). Sugerir una rutina con semana inicial de descarga.' : ''}

Formato JSON esperado:
{
  "nombre": "Nombre descriptivo de la rutina en español",
  "descripcion": "Descripcion del enfoque (max 200 caracteres)",
  "objetivo": "${perfil.objetivoPrincipal}",
  "duracionSemanas": 4,
  "estructura": {
    "1": {
      "1": [
        {"exerciseId": "...", "series": 3, "repeticiones": 10, "segundosDescanso": 90, "pesoKg": null}
      ]
    }
  }
}

La estructura debe tener ${perfil.diasDisponiblesSemana} dias en la semana 1.
Cada dia debe tener entre 4 y 7 ejercicios que cubran grupos musculares equilibrados.
Los dias deben alternar grupos musculares (ej: dia 1 torso, dia 2 pierna, dia 3 espalda/hombro).
El pesoKg debe ser null a menos que haya historial claro del usuario.
''';

    try {
      final rawJson = await _callGemini(apiKey, prompt);
      final parsed = _parseMapa(rawJson);

      final nombre = parsed['nombre'] as String? ?? 'Rutina recomendada';
      final descripcion =
          parsed['descripcion'] as String? ?? 'Rutina generada por IA';
      final objetivo =
          parsed['objetivo'] as String? ?? perfil.objetivoPrincipal;
      final duracionSemanas = (parsed['duracionSemanas'] as num?)?.toInt() ?? 4;

      final estructura = _parseEstructura(parsed);
      return RecomendacionRutinaResult(
        nombre: nombre,
        descripcion: descripcion,
        objetivo: objetivo,
        duracionSemanas: duracionSemanas,
        estructura: estructura,
      );
    } catch (e) {
      return RecomendacionRutinaResult(
        nombre: '',
        descripcion: '',
        objetivo: perfil.objetivoPrincipal,
        duracionSemanas: 4,
        estructura: const {},
        error: _parseError(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 2) Recomendación de ejercicios para un día específico
  // ---------------------------------------------------------------------------

  Future<RecomendacionEjerciciosResult> generarRecomendacionEjercicios({
    required String apiKey,
    required PerfilBienestarDb perfil,
    required List<EjercicioDb> ejerciciosDisponibles,
    required String nombreRutina,
    required String objetivoRutina,
    required int diaNum,
    required List<String> ejerciciosYaAgregados,
    HistorialSesionDto? historial,
    EstadoDiarioDb? estadoDiario,
  }) async {
    if (apiKey.trim().isEmpty) {
      return RecomendacionEjerciciosResult(
        ejercicios: const [],
        error: 'Falta GEMINI_API_KEY en el archivo .env',
      );
    }

    final equipamiento = perfil.equipamientoDisponible;
    final catalogo = ejerciciosDisponibles
        .where((e) => !ejerciciosYaAgregados.contains(e.exerciseDbId ?? e.id))
        .where((e) => _ejercicioUsaEquipamiento(e, equipamiento))
        .map((e) => {
              'exerciseId': e.exerciseDbId ?? e.id,
              'nombre': e.nombre,
              'musculosObjetivo': e.musculosObjetivo,
              'equipamientos': e.equipamientos,
            })
        .toList();

    final historialTxt = _formatearHistorial(historial);
    final estadoTxt = _formatearEstadoDiario(estadoDiario);

    final prompt = '''
Eres un entrenador personal. Recomienda entre 3 y 6 ejercicios adicionales para un dia de entrenamiento.
Responde UNICAMENTE con un array JSON valido. No uses Markdown ni bloques de codigo.

CONTEXTO:
- Rutina: "$nombreRutina"
- Objetivo de la rutina: $objetivoRutina
- Dia numero: $diaNum
- Objetivo del usuario: ${perfil.objetivoPrincipal}
- Equipamiento disponible (SOLO esto): ${equipamiento.join(', ')}
- Minutos por sesion: ${perfil.minutosPorSesion}
- Nivel de actividad: ${perfil.nivelActividad}
- Biometria: Edad ${perfil.edad}, ${perfil.pesoKg} kg, IMC ${perfil.imc.toStringAsFixed(1)}
$historialTxt

IMPORTANTE: SOLO recomienda ejercicios del catalogo. Comprueba que el equipamiento del ejercicio sea compatible con el del usuario.

Ejercicios YA agregados (NO los repitas): ${ejerciciosYaAgregados.join(', ')}

Catalogo disponible:
${json.encode(catalogo)}

SUGERENCIAS SEGUN OBJETIVO:
- perder_peso: 3-4 ejercicios compuestos, circuito, 15-20 reps, descanso 45s
- ganar_masa: 4-5 ejercicios, 8-12 reps, descanso 60-90s
- fuerza: 3-4 ejercicios compuestos, 4-6 reps, descanso 120-180s
- resistencia: 5-6 ejercicios variados, 15-25 reps, descanso 30-45s

Formato del array:
[
  {"exerciseId": "...", "series": 3, "repeticiones": 10, "segundosDescanso": 90, "pesoKg": null}
]
''';

    try {
      final rawJson = await _callGemini(apiKey, prompt);
      final parsed = json.decode(rawJson) as List<dynamic>;
      final ejercicios = parsed
          .map((e) => EjercicioRecomendado.fromMap(e as Map<String, dynamic>))
          .where((e) => e.ejercicioId.isNotEmpty)
          .toList();

      if (ejercicios.isEmpty) {
        return const RecomendacionEjerciciosResult(
          ejercicios: [],
          error: 'Gemini no genero ejercicios validos',
        );
      }

      return RecomendacionEjerciciosResult(ejercicios: ejercicios);
    } catch (e) {
      return RecomendacionEjerciciosResult(
        ejercicios: const [],
        error: _parseError(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 3) Generación de estructura completa (semanas × días)
  // ---------------------------------------------------------------------------

  Future<RecomendacionRutinaResult> generarEstructuraCompleta({
    required String apiKey,
    required PerfilBienestarDb perfil,
    required List<EjercicioDb> ejerciciosDisponibles,
    required String nombreRutina,
    required String descripcionRutina,
    required String objetivoRutina,
    required int duracionSemanas,
    required int diasPorSemana,
    HistorialSesionDto? historial,
    EstadoDiarioDb? estadoDiario,
  }) async {
    if (apiKey.trim().isEmpty) {
      return RecomendacionRutinaResult(
        nombre: '',
        descripcion: '',
        objetivo: objetivoRutina,
        duracionSemanas: duracionSemanas,
        estructura: const {},
        error: 'Falta GEMINI_API_KEY en el archivo .env',
      );
    }

    final equipamiento = perfil.equipamientoDisponible;
    final ejerciciosFiltrados = ejerciciosDisponibles
        .where((e) => _ejercicioUsaEquipamiento(e, equipamiento))
        .toList();

    if (ejerciciosFiltrados.isEmpty) {
      return RecomendacionRutinaResult(
        nombre: nombreRutina,
        descripcion: descripcionRutina,
        objetivo: objetivoRutina,
        duracionSemanas: duracionSemanas,
        estructura: const {},
        error:
            'No hay ejercicios compatibles con tu equipamiento (${equipamiento.join(", ")}).',
      );
    }

    final catalogo = ejerciciosFiltrados
        .map((e) => {
              'exerciseId': e.exerciseDbId ?? e.id,
              'nombre': e.nombre,
              'musculosObjetivo': e.musculosObjetivo,
              'equipamientos': e.equipamientos,
            })
        .toList();

    final historialTxt = _formatearHistorial(historial);
    final estadoTxt = _formatearEstadoDiario(estadoDiario);
    final seguridadIMC = _reglasSeguridadIMC(perfil.imc, perfil.edad);
    final periodizacion = _reglasPeriodizacion(duracionSemanas, historial);

    final prompt = '''
Eres un entrenador personal profesional. Genera la estructura completa de ejercicios para una rutina ya configurada.
Responde UNICAMENTE con un JSON valido. No uses Markdown ni bloques de codigo.

RUTINA CONFIGURADA POR EL USUARIO:
- Nombre: "$nombreRutina"
- Descripcion: "$descripcionRutina"
- Objetivo: $objetivoRutina
- Semanas totales: $duracionSemanas
- Dias por semana: $diasPorSemana

PERFIL DEL USUARIO:
- Objetivo: ${perfil.objetivoPrincipal}
- Nivel de actividad: ${perfil.nivelActividad}
- Equipamiento disponible (SOLO esto): ${equipamiento.join(', ')}
- Minutos por sesion: ${perfil.minutosPorSesion}
- Biometria: Edad ${perfil.edad}, Sexo ${perfil.sexo}, Peso ${perfil.pesoKg} kg, Altura ${perfil.alturaCm} cm, IMC ${perfil.imc.toStringAsFixed(1)} (${perfil.imcCategoria})
$historialTxt
$estadoTxt

REGLAS DE SEGURIDAD (obligatorio):
$seguridadIMC

REGLAS DE EQUIPAMIENTO (obligatorio):
- SOLO recomienda ejercicios que usen el equipamiento listado.
- Comprueba el campo "equipamientos" de cada ejercicio del catalogo.

PERIODIZACION (DEBES seguir esta estructura):
$periodizacion

REGLAS DE PROGRAMACION SEGUN OBJETIVO:
${_reglasPorObjetivo(objetivoRutina)}

Los dias deben alternar grupos musculares. No repitas el mismo grupo muscular en dias consecutivos.
Cada dia debe tener minimo 4 ejercicios, maximo 7.
${historial != null && historial.ejerciciosRecientes.isNotEmpty ? _formatearProgresion(historial) : ''}

Catalogo de ejercicios (SOLO estos):
${json.encode(catalogo)}

Formato JSON (EXACTAMENTE $duracionSemanas semanas, $diasPorSemana dias por semana):
{
  "estructura": {
    "1": {
      "1": [{"exerciseId": "...", "series": 3, "repeticiones": 10, "segundosDescanso": 90, "pesoKg": null}],
      "2": [...]
    },
    "2": {
      "1": [...],
      "2": [...]
    }
  }
}
''';

    try {
      final rawJson = await _callGemini(apiKey, prompt);
      final parsed = _parseMapa(rawJson);

      final estructura = _parseEstructura(parsed);
      return RecomendacionRutinaResult(
        nombre: nombreRutina,
        descripcion: descripcionRutina,
        objetivo: objetivoRutina,
        duracionSemanas: duracionSemanas,
        estructura: estructura,
      );
    } catch (e) {
      return RecomendacionRutinaResult(
        nombre: '',
        descripcion: '',
        objetivo: objetivoRutina,
        duracionSemanas: duracionSemanas,
        estructura: const {},
        error: _parseError(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 4) Progresión de un ejercicio específico (sobrecarga progresiva)
  // ---------------------------------------------------------------------------

  Future<EjercicioRecomendado?> generarProgresionEjercicio({
    required String apiKey,
    required PerfilBienestarDb perfil,
    required String nombreEjercicio,
    required String objetivoRutina,
    required List<EjericicioRecienteDto> historialEjercicio,
    double rpeUltimaSesion = 7.0,
  }) async {
    if (apiKey.trim().isEmpty || historialEjercicio.isEmpty) return null;

    final ultimo = historialEjercicio.first;

    final prompt = '''
Eres un entrenador personal experto en sobrecarga progresiva.
Analiza el historial de un ejercicio y sugiere la siguiente progresion.
Responde UNICAMENTE con un JSON valido.

CONTEXTO:
- Ejercicio: $nombreEjercicio
- Objetivo de la rutina: $objetivoRutina
- Objetivo del usuario: ${perfil.objetivoPrincipal}
- Perfil: Edad ${perfil.edad}, ${perfil.pesoKg} kg, IMC ${perfil.imc.toStringAsFixed(1)}

HISTORIAL DEL EJERCICIO:
${historialEjercicio.map((h) => '- ${h.ultimaFecha.toIso8601String().substring(0, 10)}: ${h.pesoPromedio.toStringAsFixed(1)} kg x ${h.repsPromedio} reps (RPE ${h.rpePromedio.toStringAsFixed(1)})').join('\n')}

ULTIMA SESION:
- Peso: ${ultimo.pesoPromedio.toStringAsFixed(1)} kg
- Reps: ${ultimo.repsPromedio}
- RPE: ${rpeUltimaSesion.toStringAsFixed(1)}

REGLAS DE PROGRESION:
- Si RPE < 7: subir peso 5-10% o aumentar 1-2 reps (el musculo esta infradesafiado)
- Si RPE 7-8: subir peso 2.5-5% o mantener reps (zona optima)
- Si RPE 8.5-9.5: mantener peso y reps (progresion sostenida)
- Si RPE = 10 (fallo): NO subir peso la proxima sesion
- Si el objetivo es fuerza: priorizar subir peso sobre reps
- Si el objetivo es ganar_masa: equilibrio peso/reps, rango 8-12
- Si el objetivo es perder_peso: mantener o bajar ligeramente el peso, subir reps

Formato JSON:
{"series": 3, "repeticiones": 10, "segundosDescanso": 90, "pesoKg": 22.5}
''';

    try {
      final rawJson = await _callGemini(apiKey, prompt);
      final parsed = _parseMapa(rawJson);
      return EjercicioRecomendado.fromMap(parsed);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers privados
  // ---------------------------------------------------------------------------

  /// Filtra ejercicios que usan equipamiento compatible con el usuario.
  /// peso_corporal siempre es compatible.
  bool _ejercicioUsaEquipamiento(
      EjercicioDb ejercicio, List<String> equipamientoUsuario) {
    if (equipamientoUsuario.contains('peso_corporal') &&
        ejercicio.equipamientos.contains('peso corporal')) {
      return true;
    }
    return ejercicio.equipamientos.any((eq) {
      final eqLower = eq.toLowerCase();
      for (final ue in equipamientoUsuario) {
        final ueLower = ue.toLowerCase();
        if (eqLower.contains(ueLower) || ueLower.contains(eqLower)) {
          return true;
        }
        // Mapeo común de equivalencias
        if (ueLower == 'mancuerna' && eqLower == 'mancuernas') return true;
        if (ueLower == 'mancuerna' && eqLower == 'mancuerna') return true;
        if (ueLower == 'barra' && eqLower == 'barra') return true;
        if (ueLower == 'polea' && eqLower == 'polea') return true;
        if (ueLower == 'maquina' && eqLower.contains('máquina')) return true;
        if (ueLower == 'banda_elastica' && eqLower == 'banda de resistencia')
          return true;
        if (ueLower == 'kettlebell' && eqLower == 'pesa rusa') return true;
      }
      return false;
    });
  }

  String _reglasSeguridadIMC(double imc, int edad) {
    final buf = StringBuffer();
    if (imc > 30) {
      buf.writeln(
          '- IMC > 30: Priorizar ejercicios de BAJO IMPACTO articular. Evitar saltos pliometricos y carrera.');
      buf.writeln(
          '- Evitar ejercicios que carguen excesivamente rodillas y zona lumbar.');
      buf.writeln(
          '- Recomendar ejercicios en maquina o con apoyo cuando sea posible.');
    } else if (imc > 25) {
      buf.writeln(
          '- IMC 25-30: Moderar ejercicios de alto impacto. Buena tecnica ante todo.');
    }
    if (imc < 18.5) {
      buf.writeln(
          '- IMC < 18.5: Evitar deficit calorico extremo. Priorizar ganancia de masa muscular.');
      buf.writeln(
          '- Evitar volumenes excesivos que impidan la recuperacion nutricional.');
    }
    if (edad > 50) {
      buf.writeln(
          '- Edad > 50: Priorizar ejercicios de fortalecimiento articular y equilibrio.');
      buf.writeln(
          '- Evitar cargas maximas (1RM). Trabajar en rangos de 8-15 reps.');
      buf.writeln('- Incluir siempre calentamiento articular de 5-10 minutos.');
    }
    if (edad < 18) {
      buf.writeln(
          '- Edad < 18: Priorizar tecnica sobre carga. Evitar pesos maximos.');
      buf.writeln(
          '- Enfasis en ejercicios con peso corporal y pesos moderados.');
    }
    if (buf.isEmpty) {
      buf.writeln('- Sin restricciones especificas por biometria.');
    }
    return buf.toString();
  }

  String _reglasPeriodizacion(
      int duracionSemanas, HistorialSesionDto? historial) {
    if (duracionSemanas <= 1) {
      return 'Rutina de 1 semana: intensidad normal, sin periodizacion.';
    }

    final buf = StringBuffer();
    buf.writeln('Estructura de periodizacion para $duracionSemanas semanas:');

    if (duracionSemanas >= 4) {
      if (historial != null && historial.requiereDescarga) {
        buf.writeln(
            '- Semana 1: DESCARGA ACTIVA (60% volumen, 50% intensidad). El usuario muestra fatiga acumulada.');
        buf.writeln(
            '- Semana 2: ADAPTACION (70% volumen, enfasis en tecnica).');
        buf.writeln(
            '- Semana 3: CARGA PROGRESIVA (85% volumen, aumentar peso/reps).');
        buf.writeln(
            '- Semana 4: CARGA MAXIMA (95% volumen, intensidad plena).');
      } else {
        buf.writeln(
            '- Semana 1: ADAPTACION (70% volumen, enfasis en aprender los ejercicios).');
        buf.writeln(
            '- Semana 2: CARGA PROGRESIVA (85% volumen, aumentar series o peso).');
        buf.writeln(
            '- Semana 3: CARGA PROGRESIVA (90% volumen, continuar progresion).');
        buf.writeln(
            '- Semana 4: DESCARGA ACTIVA (60% volumen, recuperacion activa).');
      }
    } else {
      buf.writeln(
          '- Semana 1: ADAPTACION (80% volumen, tecnica y aprendizaje).');
      for (var s = 2; s <= duracionSemanas; s++) {
        buf.writeln(
            '- Semana $s: CARGA PROGRESIVA (85-90% volumen, aumentar peso o reps).');
      }
    }
    buf.writeln(
        'NOTA: La aplicacion asigna automaticamente el tipo de cada semana (adaptacion/carga/pico/descarga) segun estas reglas. Asegurate de que el volumen y la intensidad de los ejercicios sean coherentes con el tipo de semana.');
    return buf.toString();
  }

  String _reglasPorObjetivo(String objetivo) {
    switch (objetivo) {
      case 'perder_peso':
        return '- 3-4 ejercicios compuestos, circuito\n'
            '- 15-20 reps, descanso corto 45-60s\n'
            '- Peso moderado, priorizar densidad de entrenamiento\n'
            '- Incluir al menos 1 ejercicio cardiovascular por dia';
      case 'ganar_masa':
        return '- 4-5 ejercicios, 8-12 reps, descanso 60-90s\n'
            '- Alternar grupos musculares grandes y pequenos\n'
            '- Priorizar ejercicios compuestos al inicio, aislados al final\n'
            '- Peso moderado-alto (RPE 7-9)';
      case 'fuerza':
        return '- 3-4 ejercicios compuestos prioritarios\n'
            '- 3-6 reps, descanso largo 120-180s\n'
            '- Peso alto (RPE 8-9.5)\n'
            '- Incluir al menos 2 ejercicios de calentamiento progresivo';
      case 'resistencia':
        return '- 5-6 ejercicios variados\n'
            '- 15-25 reps, descanso corto 30-45s\n'
            '- Peso bajo-moderado (RPE 5-7)\n'
            '- Alternar tren superior e inferior en el mismo dia';
      case 'movilidad':
        return '- Ejercicios de rango completo de movimiento\n'
            '- Peso corporal o ligero, 12-15 reps\n'
            '- Enfasis en tecnica, amplitud articular y control excentrico\n'
            '- Incluir ejercicios de estabilidad y equilibrio';
      default: // fitness_general
        return '- 4-5 ejercicios equilibrados\n'
            '- 10-12 reps, descanso 60-90s\n'
            '- Combinar ejercicios compuestos y aislados\n'
            '- Peso moderado (RPE 6-8)';
    }
  }

  String _formatearProgresion(HistorialSesionDto historial) {
    if (historial.ejerciciosRecientes.isEmpty) return '';
    final buf = StringBuffer();
    buf.writeln(
        'SOBRECARGA PROGRESIVA (basada en historial real del usuario):');
    for (final e in historial.ejerciciosRecientes.take(5)) {
      buf.writeln(
          '- ${e.nombreEjercicio}: ${e.pesoPromedio.toStringAsFixed(1)} kg x ${e.repsPromedio} reps (RPE ${e.rpePromedio.toStringAsFixed(1)}) ultima vez: ${e.ultimaFecha.toIso8601String().substring(0, 10)}');
    }
    buf.writeln(
        'Si incluyes alguno de estos ejercicios, sugiere una progresion logica (subir 2.5-5% el peso o 1-2 reps si el RPE fue < 8.5).');
    return buf.toString();
  }

  String _formatearHistorial(HistorialSesionDto? historial) {
    if (historial == null) return '';
    final buf = StringBuffer();
    buf.writeln('HISTORIAL DE ENTRENAMIENTO:');
    buf.writeln(
        '- Sesiones completadas: ${historial.totalSesionesCompletadas}');
    buf.writeln(
        '- RPE promedio sesiones recientes: ${historial.rpePromedio.toStringAsFixed(1)} / 10');
    buf.writeln(
        '- Dias completados esta semana: ${historial.diasCompletadosUltimaSemana}');
    buf.writeln(
        '- Semanas consecutivas entrenando: ${historial.semanasConsecutivasEntrenando}');
    if (historial.requiereDescarga) {
      buf.writeln(
          '- ALERTA: El usuario muestra signos de sobre-entrenamiento (RPE > 8). Recomendar volumen reducido.');
    }
    return buf.toString();
  }

  String _formatearEstadoDiario(EstadoDiarioDb? estado) {
    if (estado == null) return '';
    final buf = StringBuffer();
    buf.writeln('ESTADO FISICO DE HOY (Check-in diario):');
    buf.writeln('- Calidad del sueno: ${estado.calidadSueno}/5');
    buf.writeln('- Nivel de estres: ${estado.nivelEstres}/5');
    buf.writeln('- Nivel de energia: ${estado.nivelEnergia}/5');
    buf.writeln('- Dolor muscular: ${estado.dolorMuscular}/5');
    if (estado.zonasDolor.isNotEmpty) {
      buf.writeln('- Zonas con dolor: ${estado.zonasDolor.join(", ")}');
    }
    buf.writeln(
        '- Puntuacion de fatiga: ${estado.puntuacionFatiga}/100 (mayor = peor)');
    if (estado.requiereAdaptacion) {
      buf.writeln(
          '- ALERTA: El usuario necesita adaptacion hoy. Reducir volumen un 30%. Evitar ejercicios en zonas con dolor.');
      if (estado.zonasDolor.isNotEmpty) {
        buf.writeln(
            '- SUSTITUIR ejercicios que trabajen: ${estado.zonasDolor.join(", ")}. Buscar alternativas de otros grupos musculares.');
      }
      if (estado.nivelEnergia <= 2) {
        buf.writeln(
            '- Energia muy baja: priorizar movilidad y ejercicios de baja intensidad.');
      }
      if (estado.calidadSueno <= 2) {
        buf.writeln(
            '- Sueno deficiente: evitar ejercicios de alta demanda neuromuscular (peso muerto, squat maximo).');
      }
    }
    return buf.toString();
  }

  Map<String, dynamic> _parseMapa(String raw) {
    return json.decode(raw) as Map<String, dynamic>;
  }

  Map<int, Map<int, List<EjercicioRecomendado>>> _parseEstructura(
      Map<String, dynamic> parsed) {
    final raw = parsed['estructura'] as Map<String, dynamic>? ?? {};
    final Map<int, Map<int, List<EjercicioRecomendado>>> estructura = {};

    for (final semanaEntry in raw.entries) {
      final semanaNum = int.tryParse(semanaEntry.key) ?? 1;
      final diasRaw = semanaEntry.value as Map<String, dynamic>? ?? {};
      final Map<int, List<EjercicioRecomendado>> dias = {};

      for (final diaEntry in diasRaw.entries) {
        final diaNum = int.tryParse(diaEntry.key) ?? 1;
        final ejerciciosRaw = diaEntry.value as List<dynamic>? ?? [];
        final ejercicios = ejerciciosRaw
            .map((e) => EjercicioRecomendado.fromMap(e as Map<String, dynamic>))
            .where((e) => e.ejercicioId.isNotEmpty)
            .toList();
        if (ejercicios.isNotEmpty) dias[diaNum] = ejercicios;
      }

      if (dias.isNotEmpty) estructura[semanaNum] = dias;
    }
    return estructura;
  }

  Future<String> _callGemini(String apiKey, String prompt) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': apiKey,
        },
      ),
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      },
    );

    final data = response.data;
    final candidates =
        (data?['candidates'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    final text = candidates.isNotEmpty ? candidates.first['content'] : null;
    final parts = (text is Map<String, dynamic>)
        ? (text['parts'] as List<dynamic>?)
        : null;
    final partMaps =
        parts?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
    final raw = partMaps.isNotEmpty ? partMaps.first['text']?.toString() : null;

    if (raw == null || raw.trim().isEmpty) {
      throw Exception('Gemini no devolvio respuesta valida');
    }

    return _extraerJson(raw);
  }

  String _extraerJson(String raw) {
    final trimmed = raw.trim();

    final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = codeBlock.firstMatch(trimmed);
    if (match != null) return match.group(1)!.trim();

    final firstBrace = trimmed.indexOf('{');
    final firstBracket = trimmed.indexOf('[');

    if (firstBrace == -1 && firstBracket == -1) {
      throw Exception('No se encontro JSON en la respuesta de Gemini');
    }

    int start;
    String closeChar;
    if (firstBrace != -1 && (firstBracket == -1 || firstBrace < firstBracket)) {
      start = firstBrace;
      closeChar = '}';
    } else {
      start = firstBracket;
      closeChar = ']';
    }

    final lastClose = trimmed.lastIndexOf(closeChar);
    if (lastClose == -1) {
      throw Exception('JSON incompleto en la respuesta de Gemini');
    }

    return trimmed.substring(start, lastClose + 1);
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        return 'Error de autenticacion con Gemini. Revisa GEMINI_API_KEY.';
      }
      return 'No se pudo conectar con Gemini en este momento.';
    }
    if (e is FormatException) {
      return 'Gemini genero una respuesta con formato no valido. Intentalo de nuevo.';
    }
    return 'Error inesperado: ${e.toString().substring(0, 100)}';
  }
}
