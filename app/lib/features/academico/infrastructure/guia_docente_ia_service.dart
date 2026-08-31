import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';
import '../domain/guia_docente_dto.dart';

class GuiaDocenteIaException implements Exception {
  const GuiaDocenteIaException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Servicio que envía un PDF de Guía Docente a Gemini y extrae la estructura
/// de la asignatura: profesores, temario y criterios de evaluación.
class GuiaDocenteIaService {
  GuiaDocenteIaService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 120),
              sendTimeout: const Duration(seconds: 60),
            ));

  final Dio _dio;

  /// Endpoint dinámico: el modelo se configura vía `GEMINI_MODEL`.
  static String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/${EnvConfig.geminiModel}:generateContent';

  bool get disponible => EnvConfig.hasGeminiApiKey;

  static const _systemPrompt = '''
Analiza esta guía docente y devuelve un JSON estricto con:
1) "profesores": array con nombre, email y despacho.
2) "temario": array con los títulos de los temas teóricos y prácticos. Cada tema debe ser un objeto con "titulo" (string) y "tipo" (string: "teoria" o "practica").
3) "evaluacion": array de objetos con el nombre de la prueba (ej. Examen, Prácticas) y su "porcentaje" exacto sobre la nota final (ej. 60, 30). El porcentaje debe ser numérico, sin el símbolo %.
4) "bibliografia": array de strings con las referencias bibliográficas completas citadas en la guía docente (formato APA o similar). Si no hay bibliografia, devuelve array vacío.
Devuelve solo JSON sin markdown.''';

  Future<GuiaDocenteDto> extraerDesdePdf(
    Uint8List pdfBytes, {
    String mimeType = 'application/pdf',
  }) async {
    _verificarClave();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': EnvConfig.geminiApiKey,
        }),
        data: {
          'contents': [
            {
              'parts': [
                {'text': _systemPrompt},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Encode(pdfBytes),
                  }
                },
              ],
            }
          ],
          'generationConfig': {
            'response_mime_type': 'application/json',
            'temperature': 0.1,
          },
        },
      );
      final texto = _extraerTexto(res.data);
      if (texto == null || texto.trim().isEmpty) {
        throw const GuiaDocenteIaException(
            'La IA no devolvió ningún contenido.');
      }
      final json = _decodificarJson(texto);
      final dto = GuiaDocenteDto.fromMap(json);
      if (!dto.tieneDatos) {
        throw const GuiaDocenteIaException(
            'No se pudieron extraer datos de la guía docente. '
            'Asegúrate de que el PDF contenga el plan de estudios.');
      }
      return dto;
    } on GuiaDocenteIaException {
      rethrow;
    } on DioException catch (e) {
      throw GuiaDocenteIaException(_mensajeDio(e));
    } catch (e) {
      throw GuiaDocenteIaException('Error inesperado al analizar la guía: $e');
    }
  }

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
      throw const GuiaDocenteIaException('La IA no devolvió un JSON válido.');
    }
    return decoded;
  }

  void _verificarClave() {
    if (!EnvConfig.hasGeminiApiKey) {
      throw const GuiaDocenteIaException(
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
        return 'Tiempo de espera agotado al procesar la guía docente.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servicio de IA.';
      default:
        return 'Error de IA${status != null ? ' ($status)' : ''}.';
    }
  }
}
