import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/config/env_config.dart';
import '../domain/calendar_dtos.dart';

/// Servicio de IA para time-blocking académico usando Gemini Flash.
class TimeblockIaService {
  TimeblockIaService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 15),
            ));

  final Dio _dio;

  /// Genera un plan semanal completo mediante Gemini.
  Future<SemanaGenerada> generarSemana(InboxConfig config) async {
    if (!EnvConfig.hasGeminiApiKey) {
      return _generarHeuristico(config);
    }

    try {
      final prompt = _construirPrompt(config);

      final response = await _dio.post<Map<String, dynamic>>(
        'https://generativelanguage.googleapis.com/v1beta/models/${EnvConfig.geminiModel}:generateContent',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': EnvConfig.geminiApiKey,
        }),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'response_mime_type': 'application/json',
            'temperature': 0.4,
            'topP': 0.8,
            'topK': 40,
          },
        },
      );

      final raw = _extraerTextoRespuesta(response.data);
      if (raw == null) return _generarHeuristico(config);

      final jsonStr = _extraerJson(raw);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SemanaGenerada.fromJson(parsed);
    } catch (_) {
      return _generarHeuristico(config);
    }
  }

  // ---------------------------------------------------------------------------
  // Prompt
  // ---------------------------------------------------------------------------

  String _construirPrompt(InboxConfig config) {
    final entregasStr = config.entregas.isEmpty
        ? 'No hay entregas pendientes esta semana.'
        : config.entregas
            .map((e) =>
                '- ${e.titulo} (${e.tipo}, dificultad: ${e.dificultad}, '
                'fecha límite: ${e.fechaLimite.toIso8601String().split('T')[0]}, '
                'asignatura: ${e.asignaturaNombre ?? "Sin asignatura"})')
            .join('\n');

    final horariosFijosStr = config.horariosFijos.isEmpty
        ? 'No hay horarios fijos.'
        : config.horariosFijos
            .map((h) => '- Día ${h.diaSemana}: ${h.titulo} (${h.tipo.name}) '
                'de ${_fmtHora(h.horaInicio)} a ${_fmtHora(h.horaFin)}')
            .join('\n');

    final asignaturasStr = config.asignaturasActivas.isEmpty
        ? 'No hay asignaturas activas.'
        : config.asignaturasActivas
            .map((a) =>
                '- ${a.nombre} (créditos: ${a.creditos}, dificultad: ${a.dificultad})')
            .join('\n');

    final rutinasStr = config.rutinasActivas.isEmpty
        ? 'No hay rutinas deportivas disponibles.'
        : config.rutinasActivas
            .map((r) =>
                '- ${r.nombre} (objetivo: ${r.objetivo}, ${r.cantidadEjercicios} ejercicios, semana ${r.duracionSemanas})')
            .join('\n');

    return '''
Eres un planificador académico y deportivo para estudiantes universitarios.
Tu tarea es generar un plan semanal optimizado en formato JSON.
Responde ÚNICAMENTE con el JSON. Sin Markdown, sin bloques de código, sin texto adicional.

=== CONTEXTO DEL USUARIO ===
- Objetivo de estudio semanal: ${config.horasEstudioObjetivo.toStringAsFixed(1)} horas
- Sesiones de deporte objetivo: ${config.sesionesDeporteObjetivo} sesiones
- Duración por sesión deportiva: ${config.minutosPorSesionDeporte} minutos
- Total horas deporte objetivo: ${config.totalHorasDeporteSemana.toStringAsFixed(1)} horas

=== ENTREGAS Y EXÁMENES PRÓXIMOS ===
$entregasStr

=== ASIGNATURAS ACTIVAS ===
$asignaturasStr

=== RUTINAS DEPORTIVAS DISPONIBLES ===
$rutinasStr

=== HORARIOS FIJOS (ZONAS PROHIBIDAS — NO PUEDES COLOCAR BLOQUES EN ESTOS HORARIOS) ===
$horariosFijosStr

=== REGLAS INQUEBRANTABLES ===
N1. PRIORIZACIÓN DE ENTREGAS: Los bloques de estudio deben colocarse 1-3 días antes de cada fecha límite.
N2. FRANJA PREFERENTE ESTUDIO: Los bloques de estudio se colocan preferentemente entre 15:00 y 22:00.
N3. FRANJA PREFERENTE DEPORTE: Las sesiones deportivas se colocan preferentemente entre 17:00 y 21:00.
N4. DURACIÓN ESTUDIO: Cada bloque de estudio debe durar entre 60 y 150 minutos.
N5. DURACIÓN DEPORTE: Cada sesión deportiva debe durar exactamente ${config.minutosPorSesionDeporte} minutos.
N6. DISTRIBUCIÓN SEMANAL: Distribuye el estudio en al menos 5 días distintos.
N7. DESCANSO ENTRE BLOQUES: Deja al menos 30 minutos entre bloques consecutivos del mismo tipo.
N8. ASIGNATURAS PESADAS PRIMERO: Las asignaturas con dificultad "alta" deben tener al menos 2 bloques antes de las 18:00.
N9. DESCANSO NOCTURNO: No coloques ningún bloque después de las 22:00.
N10. EQUILIBRIO CARGA: La carga diaria total no debe superar las 6 horas en ningún día.

=== REGLAS ADICIONALES ===
H1. No solapes bloques de estudio con bloques de deporte si la carga diaria supera las 4 horas.
H2. Si una entrega tiene dificultad "alta", asigna al menos 3 bloques de estudio para esa asignatura.
H3. Prioriza bloques de ${config.tMaxEstudioMinutos} minutos para estudio profundo; usa bloques de ${(config.tMaxEstudioMinutos * 0.6).round()} minutos para repaso ligero.
H4. Las sesiones deportivas deben espaciarse al menos 48 horas entre sí.
H5. Los sábados prioriza repaso ligero (60 min); los domingos evita colocar bloques de estudio.

=== FORMATO JSON EXACTO REQUERIDO ===
{
  "semana": {
    "lunes": [
      {"tipo": "estudio", "hora_inicio": "16:00", "hora_fin": "17:30", "asignatura": "Álgebra", "tema": "Matrices y determinantes"},
      {"tipo": "deporte", "hora_inicio": "18:00", "hora_fin": "19:00", "rutina": "Rutina de Torso"}
    ],
    "martes": [...],
    "miercoles": [...],
    "jueves": [...],
    "viernes": [...],
    "sabado": [...],
    "domingo": [...]
  },
  "metadata": {
    "horas_estudio_colocadas": 20.5,
    "sesiones_deporte_colocadas": 3,
    "horas_deporte_colocadas": 3.0
  }
}

=== INSTRUCCIONES FINALES ===
- Usa EXACTAMENTE las claves: "lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo".
- Para cada bloque: "tipo" debe ser "estudio" o "deporte".
- "hora_inicio" y "hora_fin" en formato "HH:mm" (24h).
- El campo "asignatura" debe coincidir EXACTAMENTE con el nombre de una asignatura activa.
- El campo "rutina" debe coincidir EXACTAMENTE con el nombre de una rutina disponible.
- El campo "tema" debe ser específico (máximo 5 palabras).
- NO uses arrays numéricos para días. Usa objetos con nombres de día en español.
- Responde ÚNICAMENTE con el JSON. Sin Markdown, sin explicaciones.
''';
  }

  // ---------------------------------------------------------------------------
  // Fallback heurístico
  // ---------------------------------------------------------------------------

  SemanaGenerada _generarHeuristico(InboxConfig config) {
    final dias = <DiaGenerado>[];

    final horasPorDia = config.horasEstudioObjetivo / 5;
    final diasDeporte = <int>{};
    var restantes = config.sesionesDeporteObjetivo;
    for (final dia in [1, 3, 5, 2, 4]) {
      if (restantes <= 0) break;
      diasDeporte.add(dia);
      restantes--;
    }

    for (var d = 1; d <= 7; d++) {
      final bloques = <BloqueGenerado>[];

      if (d <= 5 && horasPorDia >= 1.0) {
        final cantidadBloques = (horasPorDia / 1.5).ceil().clamp(1, 2);
        var hora = 16;
        for (var b = 0; b < cantidadBloques; b++) {
          final maxHoras = config.tMaxEstudioMinutos / 60.0;
          final duracion = (horasPorDia / cantidadBloques).clamp(0.5, maxHoras);
          final hInicio = hora;
          final hFin = hora + duracion.toInt();
          final mFin = ((duracion - duracion.toInt()) * 60).toInt();
          bloques.add(BloqueGenerado(
            tipo: TimeBlockTipo.estudio,
            horaInicio: '${hInicio.toString().padLeft(2, '0')}:00',
            horaFin:
                '${hFin.toString().padLeft(2, '0')}:${mFin.toString().padLeft(2, '0')}',
            asignatura: config.asignaturasActivas.isNotEmpty
                ? config
                    .asignaturasActivas[b % config.asignaturasActivas.length]
                    .nombre
                : null,
            tema: 'Repaso general',
          ));
          hora = hFin;
          if (mFin > 0) hora++;
        }
      }

      if (diasDeporte.contains(d)) {
        final duracion = config.minutosPorSesionDeporte;
        const hInicio = 18;
        final hFin = hInicio + duracion ~/ 60;
        final mFin = duracion % 60;
        bloques.add(BloqueGenerado(
          tipo: TimeBlockTipo.deporte,
          horaInicio: '${hInicio.toString().padLeft(2, '0')}:00',
          horaFin:
              '${hFin.toString().padLeft(2, '0')}:${mFin.toString().padLeft(2, '0')}',
          rutina: config.rutinasActivas.isNotEmpty
              ? config.rutinasActivas.first.nombre
              : null,
        ));
      }

      dias.add(DiaGenerado(diaSemana: d, bloques: bloques));
    }

    final horasEstudio = config.horasEstudioObjetivo;
    final horasDeporte =
        config.sesionesDeporteObjetivo * config.minutosPorSesionDeporte / 60.0;
    return SemanaGenerada(
      dias: dias,
      metadata: WeekPlanMetadata(
        horasEstudioColocadas: horasEstudio,
        sesionesDeporteColocadas: config.sesionesDeporteObjetivo,
        horasDeporteColocadas: horasDeporte,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Utilidades de parseo
  // ---------------------------------------------------------------------------

  String? _extraerTextoRespuesta(Map<String, dynamic>? data) {
    final candidates =
        (data?['candidates'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    if (candidates.isEmpty) return null;
    final content = candidates.first['content'];
    if (content is! Map<String, dynamic>) return null;
    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;
    final text = parts.first['text'];
    return text?.toString();
  }

  String _extraerJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return raw.substring(start, end + 1);
    }
    return raw;
  }

  String _fmtHora(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
