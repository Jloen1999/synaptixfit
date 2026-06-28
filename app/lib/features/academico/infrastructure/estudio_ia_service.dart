import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';
import '../domain/fuente_estudio.dart';
import '../domain/mapa_mental.dart';

/// Excepción del asistente de estudio con IA (resúmenes y mapas mentales).
class EstudioIaException implements Exception {
  const EstudioIaException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Servicio que usa Gemini para asistir el estudio: genera resúmenes y mapas
/// mentales a partir de apuntes (texto) o archivos (PDF/imagen).
///
/// Reutiliza el mismo endpoint y patrón multimodal (`inline_data` base64) que
/// [AiScheduleParserService].
class EstudioIaService {
  EstudioIaService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 120),
              sendTimeout: const Duration(seconds: 60),
            ));

  final Dio _dio;

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  bool get disponible => EnvConfig.hasGeminiApiKey;

  // ── API pública ────────────────────────────────────────────────────────────

  /// Genera un resumen en Markdown de la [fuente].
  Future<String> resumir(FuenteEstudio fuente) async {
    _verificarClave();
    final parts =
        await _partsDesdeFuente(fuente, _promptResumen(fuente.titulo));
    final texto = await _generarTexto(parts, jsonMode: false);
    return texto.trim();
  }

  /// Genera un mapa mental jerárquico de la [fuente].
  Future<MapaMental> mapaMental(FuenteEstudio fuente) async {
    _verificarClave();
    final parts = await _partsDesdeFuente(fuente, _promptMapa(fuente.titulo));
    final texto = await _generarTexto(parts, jsonMode: true);
    final json = _decodificarJson(texto);
    final mapa = MapaMental.fromJson(json);
    if (mapa.vacio) {
      throw const EstudioIaException(
          'No se pudo generar el mapa mental a partir del material.');
    }
    return mapa;
  }

  /// Genera un banco de preguntas de práctica (opción múltiple y rellenar
  /// huecos) a partir de la [fuente] de estudio.
  /// Devuelve un mapa con clave 'preguntas' → lista de objetos pregunta.
  Future<List<Map<String, dynamic>>> generarPractica(
      FuenteEstudio fuente) async {
    _verificarClave();
    final parts =
        await _partsDesdeFuente(fuente, _promptPractica(fuente.titulo));
    final texto = await _generarTexto(parts, jsonMode: true);
    final json = _decodificarJson(texto);
    final preguntas = json['preguntas'];
    if (preguntas is! List || preguntas.isEmpty) {
      throw const EstudioIaException(
          'No se pudieron generar preguntas a partir del material.');
    }
    return preguntas.cast<Map<String, dynamic>>();
  }

  // ── Prompts ──────────────────────────────────────────────────────────────

  String _promptResumen(String titulo) => '''
Eres un asistente de estudio para estudiantes universitarios. Resume el siguiente material titulado "$titulo".
Devuelve un resumen claro y bien estructurado en español usando Markdown:
- Un párrafo introductorio breve que sitúe el tema.
- Secciones con encabezados de nivel 2 (##) para los temas principales.
- Listas con viñetas para las ideas clave.
- Usa **negrita** en los conceptos y términos importantes.
- Termina con una sección "## Puntos clave" con 3 a 5 viñetas que resuman lo esencial.
No inventes información que no esté en el material. Sé conciso pero completo.''';

  String _promptMapa(String titulo) => '''
Eres un asistente de estudio. Crea un MAPA MENTAL jerárquico del material titulado "$titulo" para ayudar a memorizar y comprender.
Devuelve EXCLUSIVAMENTE un objeto JSON (sin markdown, sin texto adicional) con esta forma exacta:
{
  "central": "Tema central, máximo 5 palabras",
  "ramas": [
    {
      "titulo": "Idea principal, máximo 6 palabras",
      "hijos": [
        { "titulo": "Subidea concisa", "hijos": [] }
      ]
    }
  ]
}
Reglas estrictas:
- Entre 3 y 7 ramas principales.
- Cada rama puede tener entre 0 y 5 hijos. Profundidad máxima: 3 niveles.
- Etiquetas MUY concisas: palabras clave, no frases largas.
- En español. Solo conceptos presentes en el material; no inventes.''';

  String _promptPractica(String titulo) => '''
Eres un asistente de estudio para universitarios. Genera un banco de preguntas basado EXCLUSIVAMENTE en el material titulado "$titulo".
Devuelve SOLO un objeto JSON (sin markdown, sin texto adicional) con esta forma exacta:
{
  "preguntas": [
    {
      "tipo": "opcion_multiple",
      "enunciado": "¿Qué establece la primera ley de Newton?",
      "opciones": ["Inercia", "Acción y reacción", "Fuerza y aceleración", "Gravedad"],
      "respuesta_correcta": "Inercia",
      "explicacion": "La primera ley de Newton o ley de la inercia establece que un cuerpo permanece en reposo o en movimiento rectilíneo uniforme a menos que una fuerza externa actúe sobre él."
    },
    {
      "tipo": "rellenar_hueco",
      "enunciado": "La fórmula de la segunda ley de Newton es F = ___ × a",
      "respuesta_correcta": "m",
      "explicacion": "La fuerza neta es igual a la masa por la aceleración (F = m·a)."
    }
  ]
}
Reglas estrictas:
- Exactamente 10 preguntas: 5 de opción múltiple y 5 de rellenar hueco.
- Cada opción múltiple debe tener 4 opciones, todas verosímiles pero solo una correcta.
- Las respuestas de rellenar hueco deben ser palabras o frases cortas (máx. 3 palabras).
- Enunciados claros y concisos en español. Explicaciones de 1-2 frases.
- Solo conceptos del material proporcionado. No inventes información externa.
- Ordena las preguntas de más sencilla a más difícil.''';

  // ── Construcción de la petición ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _partsDesdeFuente(
    FuenteEstudio fuente,
    String prompt,
  ) async {
    switch (fuente) {
      case FuenteTexto(:final contenido):
        final recortado = contenido.length > 24000
            ? contenido.substring(0, 24000)
            : contenido;
        return [
          {'text': prompt},
          {'text': '\n\n--- MATERIAL ---\n$recortado'},
        ];
      case FuenteArchivo(:final url, :final mimeType):
        final bytes = await _descargar(url);
        return [
          {'text': prompt},
          {
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Encode(bytes),
            }
          },
        ];
    }
  }

  Future<Uint8List> _descargar(String url) async {
    try {
      final r = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = r.data;
      if (data == null || data.isEmpty) {
        throw const EstudioIaException('No se pudo descargar el archivo.');
      }
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      throw EstudioIaException(_mensajeDio(e));
    }
  }

  Future<String> _generarTexto(
    List<Map<String, dynamic>> parts, {
    required bool jsonMode,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': EnvConfig.geminiApiKey,
        }),
        data: {
          'contents': [
            {'parts': parts}
          ],
          'generationConfig': {
            if (jsonMode) 'response_mime_type': 'application/json',
            'temperature': jsonMode ? 0.2 : 0.4,
          },
        },
      );
      final texto = _extraerTexto(res.data);
      if (texto == null || texto.trim().isEmpty) {
        throw const EstudioIaException('La IA no devolvió ningún contenido.');
      }
      return texto;
    } on EstudioIaException {
      rethrow;
    } on DioException catch (e) {
      throw EstudioIaException(_mensajeDio(e));
    } catch (e) {
      throw EstudioIaException('Error inesperado de IA: $e');
    }
  }

  // ── Parseo de la respuesta ─────────────────────────────────────────────────

  String? _extraerTexto(Map<String, dynamic>? data) {
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

  Map<String, dynamic> _decodificarJson(String raw) {
    var s = raw
        .trim()
        .replaceAll(RegExp(r'^```(json)?', caseSensitive: false), '')
        .replaceAll(RegExp(r'```$'), '')
        .trim();
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start != -1 && end > start) {
      s = s.substring(start, end + 1);
    }
    final decoded = jsonDecode(s);
    if (decoded is! Map<String, dynamic>) {
      throw const EstudioIaException('La IA no devolvió un JSON válido.');
    }
    return decoded;
  }

  void _verificarClave() {
    if (!EnvConfig.hasGeminiApiKey) {
      throw const EstudioIaException(
          'La IA no está configurada (falta GEMINI_API_KEY).');
    }
  }

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
        return 'Tiempo de espera agotado al procesar el material.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servicio de IA.';
      default:
        return 'Error de IA${status != null ? ' ($status)' : ''}.';
    }
  }
}
