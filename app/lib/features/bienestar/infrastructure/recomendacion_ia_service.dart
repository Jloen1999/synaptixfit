import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/db_models.dart';
import '../application/ejercicios_provider.dart';
import '../domain/ejercicio_recomendado_dto.dart';
import '../domain/historial_sesion_dto.dart';
import '../domain/recomendacion_result_dto.dart';
import 'parametros_objetivo.dart';
import 'recomendacion_contexto_service.dart';

// =============================================================================
// Servicio
// =============================================================================

class RecomendacionIaService {
  RecomendacionIaService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 45),
              sendTimeout: const Duration(seconds: 15),
            ));

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
      return const RecomendacionRutinaResult(
        nombre: '',
        descripcion: '',
        objetivo: 'fuerza',
        duracionSemanas: 4,
        estructura: {},
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
- Acondicionamiento Metabólico: circuitos, altas repeticiones (15-20), poco descanso (45-60s), peso moderado, ejercicios compuestos
- Hipertrofia Muscular: rangos de hipertrofia (8-12 reps), descanso 60-90s, ejercicios compuestos y aislados, peso moderado-alto
- Fuerza Máxima: bajas repeticiones (3-6), descanso largo (120-180s), ejercicios compuestos prioritarios, peso alto
- Fuerza Resistencia: altas repeticiones (15-25), descanso corto (30-45s), peso bajo-moderado
- Movilidad y Flexibilidad: ejercicios de rango completo, peso corporal o ligero, enfasis en tecnica
- Estabilidad y Control Motor: ejercicios de control y equilibrio (6-12 reps), descanso 45-90s, peso bajo-moderado
- Potencia y Explosividad: bajas repeticiones (1-5), descanso largo (120-240s), movimientos explosivos

REGLAS DE SERIES POR EJERCICIO (PERSONALIZA "series" PARA CADA EJERCICIO, NO uses siempre 3):
- El numero de series DEBE variar segun el contexto. NO asignes 3 series a todos los ejercicios.
- Acondicionamiento Metabólico: 2-3 series por ejercicio (priorizar densidad, no volumen por ejercicio)
- Hipertrofia Muscular: 3-4 series por ejercicio (ejercicios compuestos 4, aislados 3)
- Fuerza Máxima: 3-5 series por ejercicio (ejercicios compuestos principales 4-5, accesorios 3)
- Fuerza Resistencia: 2-3 series por ejercicio (mas ejercicios variados, menos series cada uno)
- Movilidad y Flexibilidad: 2-3 series por ejercicio (enfasis en calidad, no cantidad)
- Estabilidad y Control Motor: 2-3 series por ejercicio
- Potencia y Explosividad: 3-5 series por ejercicio
- Ajusta las series segun los minutos por sesion:
  - Menos de 30 min: reduce series (2-3 maximo por ejercicio)
  - 30-45 min: series moderadas (2-4 por ejercicio)
  - 45-90 min: series completas (3-5 por ejercicio)
  - Mas de 90 min: series maximas (4-5 por ejercicio)
- Ejercicios compuestos (sentadilla, press banca, peso muerto, dominadas): +1 serie extra
- Ejercicios aislados (curl, extension): -1 serie menos que los compuestos
- Si el estado diario muestra fatiga alta (puntuacion > 50): reduce 1 serie a todos los ejercicios
- Semana de ADAPTACION: 2-3 series. Semana de CARGA: 3-4 series. Semana de PICO: 4-5 series. Semana de DESCARGA: 2 series.

PERIODIZACION (las semanas se etiquetan automaticamente):
- Semana 1: ADAPTACION (70% volumen, enfasis en tecnica y aprendizaje)
- Semanas intermedias: CARGA PROGRESIVA (85-90% volumen, aumentar peso/reps)
${'Si la rutina dura 4+ semanas, la ultima semana es DESCARGA ACTIVA (60% volumen, recuperacion). Esto es obligatorio para prevenir sobre-entrenamiento.'}
${historial != null && historial.requiereDescarga ? '- ATENCION: El usuario muestra signos de fatiga (RPE promedio ${historial.rpePromedio.toStringAsFixed(1)}). Sugerir una rutina con semana inicial de descarga.' : ''}

Formato JSON esperado:
{
  "nombre": "Nombre descriptivo de la rutina en español",
  "descripcion": "Descripcion del enfoque (max 200 caracteres)",
  "objetivo": "${sanitizarObjetivo(perfil.objetivoPrincipal)}",
  "duracionSemanas": 4,
  "estructura": {
    "1": {
      "1": [
        {"exerciseId": "...", "series": 4, "repeticiones": 8, "segundosDescanso": 90, "pesoKg": null, "duracionSegundos": null, "distanciaMetros": null, "tiempoIsometricoSegundos": null}
      ]
    }
  }
}

REGLAS SEGUN FINALIDAD DEL EJERCICIO (campo "finalidad" en el catalogo):
- Hipertrofia Muscular / Fuerza Máxima / Fuerza Resistencia: Usa "series", "repeticiones", "segundosDescanso" y "pesoKg" (los otros campos en null).
- Acondicionamiento Metabólico: Usa "duracionSegundos" (duracion en segundos), opcionalmente "distanciaMetros". "series" equivale a intervalos. PON "repeticiones": 0 y "pesoKg": null.
- Movilidad y Flexibilidad: Usa "tiempoIsometricoSegundos" (tiempo de sujecion en segundos) o "series" con "repeticiones". PON "pesoKg": null.
- Estabilidad y Control Motor: Usa "tiempoIsometricoSegundos" para ejercicios isometricos. Para dinamicos, usa "series" y "repeticiones".
- Potencia y Explosividad: Usa "series", "repeticiones", "segundosDescanso" y "pesoKg".
- NUNCA combines campos de distintas finalidades en un mismo ejercicio. Usa solo los campos que correspondan a su finalidad.

REGLAS DE CARDIO:
- Para ejercicios de cardio, recomienda entre 600 y 3600 segundos de duración (10-60 min).
- La distancia es opcional (entre 500 y 10000 metros si se especifica).
- Los intervalos (series) para cardio van de 1 a 10.
- El descanso entre intervalos de cardio es de 30-120 segundos.

REGLAS DE ISOMETRICO:
- Para ejercicios isométricos, recomienda entre 10 y 120 segundos de sujeción por serie.
- Series: 2-4 por ejercicio isométrico.

REGLAS PARA LA DESCRIPCION (campo "descripcion"):
- NO incluyas numeros concretos (dias, semanas, sesiones) porque el usuario puede modificarlos manualmente despues.
- Céntrate en la FILOSOFIA DE ENTRENAMIENTO: enfoque, tipo de ejercicios, metodologia, objetivo.
- Ejemplos correctos: "Rutina de fuerza centrada en ejercicios compuestos con progresion semanal", "Entrenamiento de hipertrofia con enfoque en volumen y descansos controlados", "Programa de resistencia con ejercicios variados de cuerpo completo".
- Ejemplos INCORRECTOS (NO uses): "Programa de 2 dias orientado a...", "Rutina de 4 semanas con...", "Plan de 3 sesiones semanales...".
- Si el usuario tiene un objetivo concreto (ej: Hipertrofia Muscular), menciona la estrategia: "Rutina de definicion con circuitos de alta densidad y descansos cortos".

IMPORTANTE: El valor de "series" en el JSON de ejemplo es solo ilustrativo. DEBES personalizarlo para cada ejercicio segun las REGLAS DE SERIES POR EJERCICIO definidas arriba. No uses el mismo numero de series para todos los ejercicios.
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
      return const RecomendacionEjerciciosResult(
        ejercicios: [],
        error: 'Falta GEMINI_API_KEY en el archivo .env',
      );
    }

    final catalogo = _filtrarCatalogoParaIA(
      catalogo: ejerciciosDisponibles,
      perfil: perfil,
      objetivo: objetivoRutina,
      excluirIds: ejerciciosYaAgregados,
    );

    final contextoTxt = _formatearContextoCompleto(
      perfil: perfil,
      historial: historial,
      estadoDiario: estadoDiario,
      objetivo: objetivoRutina,
    );

    final prompt = '''
Eres un algoritmo de programación de entrenamiento. Recomienda entre 3 y 6 ejercicios adicionales para un día específico, basándote en el perfil del usuario y el catálogo disponible.
No inventes ejercicios. Solo usa IDs del catálogo.

$contextoTxt

DATOS DE LA RUTINA:
- Nombre: "$nombreRutina" | Objetivo: $objetivoRutina | Dia: $diaNum
- Ejercicios YA agregados (NO los repitas): ${ejerciciosYaAgregados.join(', ')}

CATALOGO DISPONIBLE (solo estos IDs):
${json.encode(catalogo)}

REGLAS DE PROGRAMACION:
- Acondicionamiento Metabólico: 3-4 ejercicios compuestos, circuito, 15-20 reps, descanso 45s
- Hipertrofia Muscular: 4-5 ejercicios, 8-12 reps, descanso 60-90s
- Fuerza Máxima: 3-4 ejercicios compuestos, 4-6 reps, descanso 120-180s
- Fuerza Resistencia: 5-6 ejercicios variados, 15-25 reps, descanso 30-45s
- Movilidad y Flexibilidad: 5-6 ejercicios de rango completo, 12-15 reps, descanso 30-60s
- Estabilidad y Control Motor: 4-5 ejercicios, 6-12 reps, descanso 45-90s
- Potencia y Explosividad: 3-4 ejercicios, 1-5 reps, descanso 120-240s

REGLAS DE SERIES (PERSONALIZA, NO uses siempre 3):
- Acondicionamiento Metabólico: 2-3 | Hipertrofia Muscular: 3-4 | Fuerza Máxima: 3-5 | Fuerza Resistencia: 2-3
- Movilidad y Flexibilidad: 2-3 | Estabilidad y Control Motor: 2-3 | Potencia y Explosividad: 3-5
- Ajusta segun minutos por sesion: < 30 min → 2-3 series, 30-45 min → 2-4, 45-90 min → 3-5, > 90 min → 4-5
- Ejercicios compuestos: +1 serie. Ejercicios aislados: -1 serie.
- Si hay estado diario con fatiga alta: reduce 1 serie a todos los ejercicios.

Formato del array:
[
  {"exerciseId": "...", "series": 4, "repeticiones": 8, "segundosDescanso": 90, "pesoKg": null, "duracionSegundos": null, "distanciaMetros": null, "tiempoIsometricoSegundos": null}
]
IMPORTANTE: "series": 4 en el ejemplo es solo ilustrativo. Personaliza SIEMPRE las series para cada ejercicio segun las reglas.

REGLAS SEGUN FINALIDAD DEL EJERCICIO (campo "finalidad" en el catalogo):
- Hipertrofia Muscular / Fuerza Máxima / Fuerza Resistencia: Usa "series", "repeticiones", "segundosDescanso" y "pesoKg" (los otros campos en null).
- Acondicionamiento Metabólico: Usa "duracionSegundos" (600-3600s). Opcional "distanciaMetros". "series" = intervalos. PON "repeticiones": 0, "pesoKg": null.
- Movilidad y Flexibilidad / Estabilidad y Control Motor: Usa "tiempoIsometricoSegundos" (10-120s por serie) o "series"/"repeticiones". PON "pesoKg": null si es corporal.
- Potencia y Explosividad: Usa "series", "repeticiones", "segundosDescanso" y "pesoKg".
- NUNCA combines campos de distintas finalidades en un mismo ejercicio.
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
    final catalogo = _filtrarCatalogoParaIA(
      catalogo: ejerciciosDisponibles,
      perfil: perfil,
      objetivo: objetivoRutina,
    );

    if (catalogo.isEmpty) {
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

    final contextoTxt = _formatearContextoCompleto(
      perfil: perfil,
      historial: historial,
      estadoDiario: estadoDiario,
      objetivo: objetivoRutina,
    );
    final periodizacion = _reglasPeriodizacion(duracionSemanas, historial);

    final prompt = '''
Eres un algoritmo de programación de entrenamiento. Genera la estructura completa de ejercicios para una rutina configurada por el usuario, aplicando reglas de periodización y respetando el perfil físico.

$contextoTxt

DATOS DE LA RUTINA:
- Nombre: "$nombreRutina" | Descripcion: "$descripcionRutina"
- Objetivo: $objetivoRutina | Semanas: $duracionSemanas | Dias/semana: $diasPorSemana

PERIODIZACION (obligatorio seguir):
$periodizacion

CATALOGO DE EJERCICIOS (solo estos):
${json.encode(catalogo)}

REGLAS DE PROGRAMACION:
${_reglasPorObjetivo(objetivoRutina)}

REGLAS DE SERIES POR EJERCICIO (OBLIGATORIO personalizar para CADA ejercicio):
- El numero de series DEBE variar. NO asignes el mismo valor a todos los ejercicios.
- Acondicionamiento Metabólico: 2-3 | Hipertrofia Muscular: 3-4 | Fuerza Máxima: 3-5 | Fuerza Resistencia: 2-3
- Movilidad y Flexibilidad: 2-3 | Estabilidad y Control Motor: 2-3 | Potencia y Explosividad: 3-5
- Ajusta segun minutos por sesion (${perfil.minutosPorSesion} min): menos de 30 min → 2-3 series, 30-45 min → 2-4, 45-90 min → 3-5, mas de 90 min → 4-5
- Ejercicios compuestos (sentadilla, press banca, peso muerto, dominadas, remo): asignales +1 serie extra respecto a los aislados
- Ejercicios aislados (curl, extension de triceps, elevaciones laterales): asignales -1 serie respecto a los compuestos
- Semana de ADAPTACION: 2-3 series. Semana de CARGA: 3-4 series. Semana de PICO: 4-5 series. Semana de DESCARGA: 2 series.
- Si el estado diario muestra fatiga alta (puntuacion > 50): reduce 1 serie a TODOS los ejercicios de ese dia.
${estadoDiario != null ? '- APLICA las adaptaciones del estado fisico de hoy a las series.' : ''}

Los dias deben alternar grupos musculares. No repitas el mismo grupo muscular en dias consecutivos.
Cada dia debe tener minimo 4 ejercicios, maximo 7.
${historial != null && historial.ejerciciosRecientes.isNotEmpty ? _formatearProgresion(historial) : ''}

Formato JSON (EXACTAMENTE $duracionSemanas semanas, $diasPorSemana dias por semana):
{
  "estructura": {
    "1": {
      "1": [{"exerciseId": "...", "series": 4, "repeticiones": 8, "segundosDescanso": 90, "pesoKg": null}],
      "2": [...]
    },
    "2": {
      "1": [...],
      "2": [...]
    }
  }
}
IMPORTANTE: Los valores "series": 4 en el ejemplo son solo ilustrativos. Personaliza SIEMPRE las series para cada ejercicio segun las reglas de arriba.
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
    required List<EjercicioRecienteDto> historialEjercicio,
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
- Si el objetivo es Fuerza Máxima o Potencia y Explosividad: priorizar subir peso sobre reps. Ajusta series a 3-5.
- Si el objetivo es Hipertrofia Muscular: equilibrio peso/reps, rango 8-12. Ajusta series a 3-4.
- Si el objetivo es Acondicionamiento Metabólico: mantener o bajar ligeramente el peso, subir reps. Ajusta series a 2-3.
- Si el objetivo es Fuerza Resistencia: mantener peso bajo, aumentar reps o series (2-3 series).
- Si el objetivo es Movilidad y Flexibilidad o Estabilidad y Control Motor: priorizar tecnica y control sobre carga.
- Ajusta tambien las series segun la progresion: si el peso sube mucho, puedes bajar 1 serie para compensar.

Formato JSON:
{"series": 4, "repeticiones": 8, "segundosDescanso": 90, "pesoKg": 22.5}
IMPORTANTE: "series": 4 es ilustrativo. Personaliza las series segun el contexto del ejercicio y objetivo.
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
  // Refinamiento IA (capa opcional sobre estructura generada por reglas)
  // ---------------------------------------------------------------------------

  Future<RecomendacionRutinaResult> refinarRutina({
    required String apiKey,
    required String nombreRutina,
    required String descripcionRutina,
    required String objetivoRutina,
    required int duracionSemanas,
    required Map<int, Map<int, List<EjercicioRecomendado>>> estructuraBase,
    required PerfilBienestarDb perfil,
    required List<EjercicioDb> catalogo,
    HistorialSesionDto? historial,
    EstadoDiarioDb? estadoDiario,
    ContextoAcademico? contextoAcademico,
    String? motivoAjustes,
  }) async {
    final equipamiento = perfil.equipamientoDisponible;
    final obj = sanitizarObjetivo(objetivoRutina);
    final params = ParametrosObjetivo.de(obj);
    final contextoTxt = _formatearContextoCompleto(
      perfil: perfil,
      historial: historial,
      estadoDiario: estadoDiario,
      contextoAcademico: contextoAcademico,
      objetivo: obj,
    );
    if (catalogo.isEmpty) {
      return RecomendacionRutinaResult(
        nombre: nombreRutina,
        descripcion: descripcionRutina,
        objetivo: obj,
        duracionSemanas: duracionSemanas,
        estructura: estructuraBase,
        error: 'Catálogo de ejercicios no disponible',
      );
    }

    final estructuraResumen = StringBuffer();
    for (final semana in estructuraBase.entries) {
      estructuraResumen.writeln('Semana ${semana.key}:');
      for (final dia in semana.value.entries) {
        estructuraResumen.writeln('  Dia ${dia.key}:');
        for (final e in dia.value) {
          final match = catalogo
              .cast<EjercicioDb?>()
              .firstWhere((x) => x?.id == e.ejercicioId, orElse: () => null);
          if (match == null) {
            debugPrint(
                '[refinarRutina] Ejercicio no encontrado en catálogo: ${e.ejercicioId}');
            continue;
          }
          estructuraResumen.writeln(
              '    - ${match.nombre}  id=${e.ejercicioId}  (${e.series}x${e.repeticiones}, descanso ${e.segundosDescanso}s)');
        }
      }
    }

    final catalogoFiltrado = _filtrarCatalogoParaIA(
      catalogo: catalogo,
      perfil: perfil,
      objetivo: obj,
    );

    final prompt = '''
Eres un algoritmo de optimización deportiva. Tu tarea es refinar una rutina generada automáticamente, aplicando reglas lógicas basadas en el perfil del usuario.
No eres creativo. Sigues reglas deterministas. No inventas ejercicios.

$contextoTxt

ESTRUCTURA BASE (generada por reglas de entrenamiento):
$estructuraResumen

CATALOGO DE EJERCICIOS DISPONIBLES PARA SUSTITUCION (usa los IDs de aqui):
${json.encode(catalogoFiltrado)}

REGLAS DE REFINAMIENTO:

1. MEJORA EL NOMBRE: Hazlo mas personal y motivador. Ej: en vez de "Rutina de Fuerza", algo como "Potencia Total — Fase de Carga".

2. MEJORA LA DESCRIPCION: Explica el enfoque de forma inspiradora, SIN mencionar numeros (dias/semanas).
   ${motivoAjustes != null ? 'Menciona sutilmente que se adapto la intensidad por el contexto actual del usuario.' : ''}

3. VARIA EJERCICIOS (opcional, solo 1-2 cambios maximo por dia): Si ves un ejercicio que se repite mucho entre dias, puedes sustituirlo por otro del catalogo que trabaje los MISMOS musculos. SOLO sustituye si el nuevo ejercicio usa equipamiento COMPATIBLE (${equipamiento.join(', ')}).

4. ORDEN DE EJERCICIOS: Si hay ejercicios compuestos al final y aislados al principio, reordena (compuestos primero). NO cambies series/reps/descanso.

5. PARAMETROS: NO modifiques series, repeticiones ni descanso a menos que tengas una razon MUY clara (ej: un ejercicio compuesto deberia tener mas series que un aislado). Los valores actuales ya fueron calculados para el objetivo "$obj" (${params.seriesMin}-${params.seriesMax} series, ${params.repsMin}-${params.repsMax} reps, ${params.descansoMin}-${params.descansoMax}s descanso).

Formato JSON:
{
  "nombre": "Nombre mejorado",
  "descripcion": "Descripcion mejorada",
  "estructura": {
    "1": {
      "1": [
        {"exerciseId": "id-del-ejercicio", "series": 3, "repeticiones": 10, "segundosDescanso": 90, "pesoKg": null}
      ]
    }
  }
}

El JSON debe contener TODOS los dias y ejercicios de la estructura base. Si sustituyes un ejercicio, asegurate de que el exerciseId existe en el catalogo.
''';

    try {
      final rawJson = await _callGemini(apiKey, prompt);
      final parsed = _parseMapa(rawJson);

      final nombre = parsed['nombre'] as String? ?? nombreRutina;
      final descripcion = parsed['descripcion'] as String? ?? descripcionRutina;
      final estructuraRaw = parsed['estructura'] as Map<String, dynamic>?;

      Map<int, Map<int, List<EjercicioRecomendado>>> estructuraRefinada;
      if (estructuraRaw != null) {
        estructuraRefinada = _parseEstructura(parsed);
      } else {
        estructuraRefinada = estructuraBase;
      }

      estructuraRefinada = _validarYReparar(
        estructuraRefinada,
        estructuraBase,
        catalogo,
        equipamiento,
        perfil,
      );

      return RecomendacionRutinaResult(
        nombre: nombre,
        descripcion: descripcion,
        objetivo: obj,
        duracionSemanas: duracionSemanas,
        estructura: estructuraRefinada,
      );
    } catch (e) {
      debugPrint(
          '[refinarRutina] Error al llamar a Gemini: ${_parseError(e)} ($e)');
      return RecomendacionRutinaResult(
        nombre: nombreRutina,
        descripcion: descripcionRutina,
        objetivo: obj,
        duracionSemanas: duracionSemanas,
        estructura: estructuraBase,
        error: 'IA no disponible: ${_parseError(e)}',
      );
    }
  }

  Map<int, Map<int, List<EjercicioRecomendado>>> _validarYReparar(
    Map<int, Map<int, List<EjercicioRecomendado>>> iaOutput,
    Map<int, Map<int, List<EjercicioRecomendado>>> base,
    List<EjercicioDb> catalogo,
    List<String> equipamientoUsuario,
    PerfilBienestarDb perfil,
  ) {
    final idsValidos = catalogo.map((e) => e.id).toSet();
    final resultado = <int, Map<int, List<EjercicioRecomendado>>>{};

    for (final semana in base.entries) {
      resultado[semana.key] = {};
      final iaSemana = iaOutput[semana.key] ?? {};

      for (final dia in semana.value.entries) {
        final iaDia = iaSemana[dia.key] ?? [];
        final baseDia = dia.value;
        final reparado = <EjercicioRecomendado>[];

        for (var i = 0; i < baseDia.length && i < iaDia.length; i++) {
          final ej = _validarEjercicio(
            iaDia[i],
            baseDia[i],
            idsValidos,
            catalogo,
            equipamientoUsuario,
            perfil,
          );
          reparado.add(ej);
        }

        if (reparado.length < baseDia.length) {
          for (var i = reparado.length; i < baseDia.length; i++) {
            reparado.add(baseDia[i]);
          }
        }

        resultado[semana.key]![dia.key] = reparado;
      }
    }

    return resultado;
  }

  EjercicioRecomendado _validarEjercicio(
    EjercicioRecomendado ia,
    EjercicioRecomendado base,
    Set<String> idsValidos,
    List<EjercicioDb> catalogo,
    List<String> equipamientoUsuario,
    PerfilBienestarDb perfil,
  ) {
    if (!idsValidos.contains(ia.ejercicioId)) return base;

    final ej = catalogo.firstWhere((e) => e.id == ia.ejercicioId,
        orElse: () => catalogo.first);
    if (ej.id != ia.ejercicioId) return base;

    if (!_ejercicioUsaEquipamiento(ej, equipamientoUsuario)) return base;

    final nivelOk = switch (ej.dificultad) {
      'principiante' => true,
      'intermedio' => perfil.nivelActividad != 'sedentario',
      'avanzado' => perfil.nivelActividad == 'alto',
      _ => true,
    };
    if (!nivelOk) return base;

    final seriesOk = ia.series >= 1 && ia.series <= 10;
    final repsOk = ia.repeticiones >= 1 && ia.repeticiones <= 100;
    final descansoOk = ia.segundosDescanso >= 15 && ia.segundosDescanso <= 600;

    final duracionOk = ia.duracionSegundos == null ||
        (ia.duracionSegundos! >= 30 && ia.duracionSegundos! <= 7200);
    final distanciaOk = ia.distanciaMetros == null ||
        (ia.distanciaMetros! >= 50 && ia.distanciaMetros! <= 42195);
    final isometricoOk = ia.tiempoIsometricoSegundos == null ||
        (ia.tiempoIsometricoSegundos! >= 5 &&
            ia.tiempoIsometricoSegundos! <= 300);
    final pesoOk = ia.pesoKg == null || (ia.pesoKg! >= 0 && ia.pesoKg! <= 300);

    return EjercicioRecomendado(
      ejercicioId: ia.ejercicioId,
      series: seriesOk ? ia.series : base.series,
      repeticiones: repsOk ? ia.repeticiones : base.repeticiones,
      segundosDescanso:
          descansoOk ? ia.segundosDescanso : base.segundosDescanso,
      pesoKg: pesoOk ? ia.pesoKg : base.pesoKg,
      duracionSegundos: duracionOk && ia.duracionSegundos != null
          ? ia.duracionSegundos
          : base.duracionSegundos,
      distanciaMetros: distanciaOk && ia.distanciaMetros != null
          ? ia.distanciaMetros
          : base.distanciaMetros,
      tiempoIsometricoSegundos:
          isometricoOk && ia.tiempoIsometricoSegundos != null
              ? ia.tiempoIsometricoSegundos
              : base.tiempoIsometricoSegundos,
    );
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
        if (ueLower == 'banda_elastica' && eqLower == 'banda de resistencia') {
          return true;
        }
        if (ueLower == 'kettlebell' && eqLower == 'pesa rusa') return true;
      }
      return false;
    });
  }

  // ---------------------------------------------------------------------------
  // Catálogo inteligente para prompts de IA (Fase 1)
  // ---------------------------------------------------------------------------

  static const _topCatalogo = 60;

  List<Map<String, dynamic>> _filtrarCatalogoParaIA({
    required List<EjercicioDb> catalogo,
    required PerfilBienestarDb perfil,
    required String objetivo,
    List<String>? excluirIds,
  }) {
    final equipamiento = perfil.equipamientoDisponible;
    final excluir = excluirIds?.toSet() ?? {};

    var pool = catalogo.where((e) {
      if (excluir.contains(e.id)) return false;
      if (!_ejercicioUsaEquipamiento(e, equipamiento)) return false;
      if (!_dificultadAptaParaIA(e.dificultad, perfil.nivelActividad)) {
        return false;
      }
      return true;
    }).toList();

    pool.sort((a, b) {
      final sA = _scoreParaIA(a, objetivo);
      final sB = _scoreParaIA(b, objetivo);
      return sB.compareTo(sA);
    });

    return pool.take(_topCatalogo).map(_catalogoToJson).toList();
  }

  bool _dificultadAptaParaIA(String dificultad, String nivelActividad) {
    switch (nivelActividad) {
      case 'sedentario':
        return dificultad == 'principiante';
      case 'ligero':
        return dificultad == 'principiante' || dificultad == 'intermedio';
      case 'moderado':
        return true;
      case 'alto':
        return true;
      default:
        return dificultad == 'principiante' || dificultad == 'intermedio';
    }
  }

  double _scoreParaIA(EjercicioDb ej, String objetivo) {
    double score = 0.0;
    final objLower = objetivo.toLowerCase();
    final finalidades = ej.finalidad.map((f) => f.toLowerCase()).toSet();
    if (finalidades.contains(objLower)) score += 0.50;
    if (ej.musculosSecundarios.length >= 2 && ej.musculosObjetivo.length <= 2) {
      score += 0.20;
    }
    if (ej.finalidad.length >= 2) score += 0.15;
    switch (ej.dificultad) {
      case 'intermedio':
        score += 0.10;
        break;
      case 'principiante':
        score += 0.05;
        break;
      default:
        break;
    }
    return score.clamp(0.0, 1.0);
  }

  Map<String, dynamic> _catalogoToJson(EjercicioDb e) {
    return {
      'id': e.id,
      'nombre': e.nombre,
      'musculos': e.musculosObjetivo,
      'dificultad': e.dificultad,
      'modalidad': e.modalidadEntrenamiento,
      'tipoMedicion': e.tipoMedicion,
      'esCompuesto':
          e.musculosSecundarios.length >= 2 && e.musculosObjetivo.length <= 2,
      'finalidad': e.finalidad,
      'equipamiento': e.equipamientos,
    };
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
    final o = sanitizarObjetivo(objetivo);
    switch (o) {
      case 'Acondicionamiento Metabólico':
        return '- 3-4 ejercicios compuestos, circuito\n'
            '- 15-20 reps, descanso corto 45-60s\n'
            '- Peso moderado, priorizar densidad de entrenamiento\n'
            '- Incluir al menos 1 ejercicio cardiovascular por dia';
      case 'Hipertrofia Muscular':
        return '- 4-5 ejercicios, 8-12 reps, descanso 60-90s\n'
            '- Alternar grupos musculares grandes y pequenos\n'
            '- Priorizar ejercicios compuestos al inicio, aislados al final\n'
            '- Peso moderado-alto (RPE 7-9)';
      case 'Fuerza Máxima':
        return '- 3-4 ejercicios compuestos prioritarios\n'
            '- 3-6 reps, descanso largo 120-180s\n'
            '- Peso alto (RPE 8-9.5)\n'
            '- Incluir al menos 2 ejercicios de calentamiento progresivo';
      case 'Fuerza Resistencia':
        return '- 5-6 ejercicios variados\n'
            '- 15-25 reps, descanso corto 30-45s\n'
            '- Peso bajo-moderado (RPE 5-7)\n'
            '- Alternar tren superior e inferior en el mismo dia';
      case 'Movilidad y Flexibilidad':
        return '- Ejercicios de rango completo de movimiento\n'
            '- Peso corporal o ligero, 12-15 reps\n'
            '- Enfasis en tecnica, amplitud articular y control excentrico\n'
            '- Incluir ejercicios de estabilidad y equilibrio';
      default:
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

  String _formatearContextoCompleto({
    required PerfilBienestarDb perfil,
    required String objetivo,
    HistorialSesionDto? historial,
    EstadoDiarioDb? estadoDiario,
    ContextoAcademico? contextoAcademico,
  }) {
    final buf = StringBuffer();

    buf.writeln('PERFIL FISICO:');
    buf.writeln('- Objetivo: $objetivo | Nivel: ${perfil.nivelActividad}');
    buf.writeln(
        '- Edad: ${perfil.edad} | Peso: ${perfil.pesoKg}kg | IMC: ${perfil.imc.toStringAsFixed(1)} (${perfil.imcCategoria})');
    buf.writeln(
        '- Equipamiento: ${perfil.equipamientoDisponible.join(", ")} | Dias/sem: ${perfil.diasDisponiblesSemana} | Min/sesion: ${perfil.minutosPorSesion}');
    buf.writeln();

    if (historial != null) {
      buf.writeln('HISTORIAL DEPORTIVO:');
      buf.writeln(
          '- Sesiones: ${historial.totalSesionesCompletadas} | RPE promedio: ${historial.rpePromedio.toStringAsFixed(1)} | Semanas consecutivas: ${historial.semanasConsecutivasEntrenando}');
      buf.writeln(
          '- Dias esta semana: ${historial.diasCompletadosUltimaSemana}');
      if (historial.requiereDescarga) {
        buf.writeln('- ALERTA: Requiere descarga (fatiga acumulada).');
      }
      if (historial.ejerciciosRecientes.isNotEmpty) {
        buf.writeln('- Ejercicios recientes:');
        for (final e in historial.ejerciciosRecientes.take(5)) {
          buf.writeln(
              '  ${e.nombreEjercicio}: ${e.pesoPromedio.toStringAsFixed(1)}kg x ${e.repsPromedio} (RPE ${e.rpePromedio.toStringAsFixed(1)})');
        }
      }
      buf.writeln();
    }

    if (estadoDiario != null) {
      buf.writeln('ESTADO DIARIO:');
      buf.writeln(
          '- Sueño: ${estadoDiario.calidadSueno}/5 | Estres: ${estadoDiario.nivelEstres}/5 | Energia: ${estadoDiario.nivelEnergia}/5 | Dolor: ${estadoDiario.dolorMuscular}/5');
      buf.writeln('- Fatiga: ${estadoDiario.puntuacionFatiga}/100');
      buf.writeln(
          '- Listo para entrenar: ${estadoDiario.listoParaEntrenar ? "si" : "no"}');
      if (estadoDiario.zonasDolor.isNotEmpty) {
        buf.writeln('- Zonas con dolor: ${estadoDiario.zonasDolor.join(", ")}');
      }
      buf.writeln();
    }

    if (contextoAcademico != null) {
      buf.writeln('CARGA ACADEMICA:');
      buf.writeln(
          '- Horas estudio/semana: ${contextoAcademico.horasEstudioReales.toInt()}h | Estrés académico: ${contextoAcademico.nivelEstres.toStringAsFixed(1)}/10');
      buf.writeln(
          '- Evaluaciones esta semana: ${contextoAcademico.evaluacionesSemana} | Sueño promedio: ${contextoAcademico.horasSuenoPromedio.toStringAsFixed(1)}h');
      buf.writeln(
          '- ¿Exámenes próximos? ${contextoAcademico.tieneExamenesProximos ? "Sí (en los próximos 7 días)" : "No"}');
      buf.writeln(
          '- Adherencia académica: ${contextoAcademico.adherenciaAcademica.toStringAsFixed(0)}/100 | Estado energético: ${contextoAcademico.estadoEnergetico.toStringAsFixed(0)}/100');
      if (contextoAcademico.estadoEnergetico < 30) {
        buf.writeln(
            '- ALERTA: Estado energético crítico. Recomendar descanso o recuperación activa.');
      } else if (contextoAcademico.estadoEnergetico < 50) {
        buf.writeln('- Estado energético bajo. Reducir intensidad y volumen.');
      }
      buf.writeln();
    }

    buf.writeln('SEGURIDAD BIOMETRICA:');
    buf.writeln(_reglasSeguridadIMC(perfil.imc, perfil.edad));

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

  /// Método público para generación de texto simple vía Gemini.
  /// Usado por SmartBanner y otros widgets que necesitan prompts de texto libre.
  Future<String> generarTexto(String apiKey, String prompt) async {
    return _callGemini(apiKey, prompt, useJsonMode: false);
  }

  Future<String> _callGemini(String apiKey, String prompt,
      {bool useJsonMode = true}) async {
    final genConfig = <String, dynamic>{};
    if (useJsonMode) genConfig['response_mime_type'] = 'application/json';
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
        ],
        'generationConfig': genConfig,
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

    final trimmed = raw.trim();

    if (!useJsonMode) return trimmed;

    try {
      json.decode(trimmed);
      return trimmed;
    } on FormatException {
      return _extraerJson(raw);
    }
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
    final msg = e.toString();
    return 'Error inesperado: ${msg.length > 100 ? msg.substring(0, 100) : msg}';
  }
}
