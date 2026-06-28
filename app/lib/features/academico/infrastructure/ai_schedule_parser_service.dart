import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';

/// Excepción lanzada cuando la IA no devuelve un horario válido: array vacío
/// (ninguna asignatura encontrada), respuesta no parseable o error de red/API.
class AiParsingException implements Exception {
  const AiParsingException(this.message);
  final String message;

  @override
  String toString() => 'AiParsingException: $message';
}

/// Servicio que utiliza Gemini para analizar documentos de horarios
/// universitarios (PDF o imagen) y extraer ÚNICAMENTE el patrón semanal.
///
/// Arquitectura clave: el documento NO contiene fechas absolutas de semestre.
/// La IA solo extrae el patrón semanal; el flujo Dart adjunta las fechas
/// absolutas (perfil académico o solicitadas just-in-time) en el ensamblaje.
///
/// Nota de portabilidad: el método recibe los bytes del documento
/// ([Uint8List]) + su [mimeType] en lugar de `dart:io.File`, para que el
/// servicio compile y funcione en todas las plataformas (incluida web), que
/// es donde `dart:io` no está disponible. El llamador obtiene los bytes con
/// `file_picker` (con `withData: true`).
class AiScheduleParserService {
  AiScheduleParserService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 90),
              sendTimeout: const Duration(seconds: 30),
            ));

  final Dio _dio;

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Prompt de sistema con inyección dinámica de contexto: solo se buscan los
  /// horarios de las asignaturas activas del usuario para prevenir
  /// alucinaciones (la IA ignora cualquier otra asignatura).
  String _systemPrompt(List<String> activeSubjects) {
    final lista = activeSubjects.isEmpty
        ? '(el usuario no tiene asignaturas configuradas)'
        : activeSubjects.join(', ');
    return '''
Eres un analizador de datos determinista. Extrae el patrón semanal de clases del documento proporcionado y devuelve estrictamente un array JSON.
REGLA 1: Solo busca horarios para estas asignaturas: $lista. Ignora el resto.
REGLA 2: NUNCA inventes fechas absolutas.
REGLA 3: dia_semana es un entero (1=Lunes, 5=Viernes). Horas en formato HH:MM (24h).
REGLA 4: Si un dato no aparece en el documento, usa cadena vacía; nunca lo inventes.
Devuelve solo JSON, sin markdown. Formato exigido:
[
  {
    "asignatura_codigo": "SIGLAS",
    "asignatura_nombre": "Nombre de la asignatura encontrada",
    "tipo": "Teoría | Práctica",
    "dia_semana": 1,
    "hora_inicio": "17:00",
    "hora_fin": "19:00",
    "aula": "Aula X"
  }
]''';
  }

  /// Llama a la IA con el documento + prompt dinámico, sanea la respuesta y
  /// ensambla el paquete final inyectando las fechas absolutas recibidas.
  ///
  /// Lanza [AiParsingException] si la IA devuelve un array vacío (ninguna
  /// asignatura encontrada) o si el parseo / la red fallan.
  Future<Map<String, dynamic>> parseAndAssembleSchedule({
    required Uint8List bytes,
    required String mimeType,
    required List<String> subjects,
    required DateTime semesterStart,
    required DateTime semesterEnd,
  }) async {
    if (!EnvConfig.hasGeminiApiKey) {
      throw const AiParsingException(
          'La IA no está configurada (falta GEMINI_API_KEY).');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': EnvConfig.geminiApiKey,
        }),
        data: {
          'contents': [
            {
              'parts': [
                {'text': _systemPrompt(subjects)},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Encode(bytes),
                  }
                },
              ]
            }
          ],
          // Temperatura 0 + topK 1 → salida determinista, sin alucinaciones.
          'generationConfig': {
            'response_mime_type': 'application/json',
            'temperature': 0.0,
            'topP': 0.1,
            'topK': 1,
          },
        },
      );

      final raw = _extraerTextoRespuesta(response.data);
      if (raw == null || raw.trim().isEmpty) {
        throw const AiParsingException('La IA no devolvió ningún contenido.');
      }

      final decoded = jsonDecode(_limpiarMarkdown(raw));
      if (decoded is! List) {
        throw const AiParsingException(
            'La IA no devolvió un array JSON válido.');
      }

      // Saneamiento: solo entradas con estructura mínima coherente.
      final horarios = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where(_esEntradaValida)
          .toList();

      if (horarios.isEmpty) {
        throw const AiParsingException(
            'No se encontró ninguna de tus asignaturas en el documento.');
      }

      // Ensamblaje del paquete final para el motor de generación.
      return <String, dynamic>{
        'fecha_inicio_clases': _fmtFecha(semesterStart),
        'fecha_fin_clases': _fmtFecha(semesterEnd),
        'horarios': horarios,
      };
    } on AiParsingException {
      rethrow;
    } on DioException catch (e) {
      throw AiParsingException(_mensajeDio(e));
    } catch (e) {
      throw AiParsingException('No se pudo interpretar el horario: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Saneamiento y utilidades
  // ---------------------------------------------------------------------------

  bool _esEntradaValida(Map<String, dynamic> m) {
    final dia = m['dia_semana'];
    final diaOk = dia is int && dia >= 1 && dia <= 7;
    final inicio = m['hora_inicio'];
    final fin = m['hora_fin'];
    final horaRegex = RegExp(r'^\d{1,2}:\d{2}$');
    final horasOk = inicio is String &&
        fin is String &&
        horaRegex.hasMatch(inicio) &&
        horaRegex.hasMatch(fin);
    final nombre = m['asignatura_nombre'];
    final nombreOk = nombre is String && nombre.trim().isNotEmpty;
    return diaOk && horasOk && nombreOk;
  }

  /// Limpia bloques Markdown (```json … ```) y recorta al array JSON.
  String _limpiarMarkdown(String raw) {
    var s = raw.trim();
    s = s
        .replaceAll(RegExp(r'^```(json)?', caseSensitive: false), '')
        .replaceAll(RegExp(r'```$'), '')
        .trim();
    final start = s.indexOf('[');
    final end = s.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return s.substring(start, end + 1);
    }
    return s;
  }

  String? _extraerTextoRespuesta(Map<String, dynamic>? data) {
    final candidates =
        (data?['candidates'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    if (candidates.isEmpty) return null;
    final content = candidates.first['content'];
    if (content is! Map<String, dynamic>) return null;
    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;
    return parts.first['text']?.toString();
  }

  String _fmtFecha(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _mensajeDio(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'Clave de IA inválida o sin permisos.';
    }
    if (status == 429) {
      return 'Límite de peticiones de IA alcanzado. Inténtalo más tarde.';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Tiempo de espera agotado al analizar el documento.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servicio de IA.';
      default:
        return 'Error de IA${status != null ? ' ($status)' : ''}.';
    }
  }
}
