import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';

class ObjetivoIaResult {
  const ObjetivoIaResult({required this.sugerencias, this.error});

  final List<String> sugerencias;
  final String? error;
}

class ObjetivoIaService {
  ObjetivoIaService([Dio? dio]) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<ObjetivoIaResult> generarSugerencias({
    required String apiKey,
    String? edad,
    String? sexo,
    String? nivelActividad,
    String? ciudad,
  }) async {
    if (apiKey.trim().isEmpty) {
      return const ObjetivoIaResult(
        sugerencias: [],
        error: 'Falta GEMINI_API_KEY en el archivo .env',
      );
    }

    final prompt = '''
Eres un asistente fitness y bienestar para estudiantes.
Propón 5 objetivos principales breves, accionables y realistas en español.
Cada objetivo debe tener máximo 10 palabras.
Sin introducción ni explicación.
Responde SOLO con una lista numerada del 1 al 5.

Contexto del usuario:
- Edad: ${edad?.trim().isNotEmpty == true ? edad!.trim() : 'No especificada'}
- Sexo: ${sexo?.trim().isNotEmpty == true ? sexo!.trim() : 'No especificado'}
- Nivel de actividad: ${nivelActividad?.trim().isNotEmpty == true ? nivelActividad!.trim() : 'No especificado'}
- Ciudad: ${ciudad?.trim().isNotEmpty == true ? ciudad!.trim() : 'No especificada'}
''';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://generativelanguage.googleapis.com/v1beta/models/${EnvConfig.geminiModel}:generateContent',
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
      final candidates = (data?['candidates'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      final text = candidates.isNotEmpty ? candidates.first['content'] : null;

      final parts = (text is Map<String, dynamic>)
          ? (text['parts'] as List<dynamic>?)
          : null;
      final partMaps =
          parts?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
      final raw =
          partMaps.isNotEmpty ? partMaps.first['text']?.toString() : null;

      if (raw == null || raw.trim().isEmpty) {
        return const ObjetivoIaResult(
          sugerencias: [],
          error: 'Gemini no devolvió sugerencias válidas',
        );
      }

      final sugerencias = raw
          .split('\n')
          .map((linea) => linea.trim())
          .where((linea) => linea.isNotEmpty)
          .map((linea) =>
              linea.replaceFirst(RegExp(r'^\d+[\).\-\s]*'), '').trim())
          .where((linea) => linea.isNotEmpty)
          .toSet()
          .toList()
        ..removeWhere((s) => s.length < 4);

      if (sugerencias.isEmpty) {
        return const ObjetivoIaResult(
          sugerencias: [],
          error: 'No fue posible generar sugerencias con IA',
        );
      }

      return ObjetivoIaResult(sugerencias: sugerencias.take(5).toList());
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detalle = e.response?.data;
      final mensaje = status == 400 || status == 401 || status == 403
          ? 'Error de autenticación con Gemini. Revisa GEMINI_API_KEY.'
          : 'No se pudo conectar con Gemini en este momento.';

      return ObjetivoIaResult(
        sugerencias: const [],
        error:
            '$mensaje ${detalle != null ? '- Detalle: $detalle' : ''}'.trim(),
      );
    } catch (_) {
      return const ObjetivoIaResult(
        sugerencias: [],
        error: 'Error inesperado al generar sugerencias de IA',
      );
    }
  }
}
