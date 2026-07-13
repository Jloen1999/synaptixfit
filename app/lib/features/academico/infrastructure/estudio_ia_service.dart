import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';
import '../domain/fuente_estudio.dart';
import '../domain/mapa_mental.dart';

class EstudioIaException implements Exception {
  const EstudioIaException(this.message);
  final String message;

  @override
  String toString() => message;
}

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

  static const _systemInstruction = '''
Eres un motor de generación académica. Responde ÚNICAMENTE con el objeto JSON
solicitado. NO incluyas saludos, introducciones, conclusiones, ni texto de
relleno conversacional antes o después del JSON. NO uses frases como "Aquí
está", "Espero que te sirva", "Claro, aquí tienes". Solo devuelve el JSON puro.
''';

  String _contextoBloque(List<FuenteEstudio> fuentes) {
    final buf = StringBuffer();
    buf.writeln('[CONTEXTO DE FUENTES COMBINADAS]');
    for (var i = 0; i < fuentes.length; i++) {
      final f = fuentes[i];
      buf.writeln('Fuente ${i + 1}: "${f.titulo}"');
    }
    buf.writeln();
    buf.writeln(
        'Sintetiza TODAS las fuentes anteriores. Conecta los conceptos de forma');
    buf.writeln(
        'transversal. No trates cada fuente por separado; el objetivo es una');
    buf.writeln('visión integrada del material combinado.');
    return buf.toString();
  }

  static const _directivaTitulo =
      'titulo_personalizado: descriptivo, directo y conciso. NUNCA incluyas fechas, horas ni palabras redundantes como "Resumen", "Mapa" o "Cuestionario".';

  String _promptResumen(List<FuenteEstudio> fuentes) => '''
$_systemInstruction

TAREA: Genera un resumen académico sintetizando todas las fuentes del contexto.

ESQUEMA JSON EXACTO (responde SOLO este JSON):
{
  "titulo_personalizado": "$_directivaTitulo",
  "contenido_markdown": "# Desarrollo del tema\\n\\n..."
}

REGLAS DEL RESUMEN:
- Sintetiza y conecta los conceptos de TODAS las fuentes combinadas.
- Estructura el contenido en secciones con encabezados ##.
- Usa listas con viñetas para las ideas clave.
- Usa **negrita** en conceptos importantes.
- Termina con sección "## Puntos clave" (3-5 viñetas).
- No inventes información que no esté en las fuentes.
- Escribe en español.
$_contextoBloque(fuentes)''';

  String _promptMapaMental(List<FuenteEstudio> fuentes) => '''
$_systemInstruction

TAREA: Genera un mapa mental jerárquico sintetizando todas las fuentes.

ESQUEMA JSON EXACTO (responde SOLO este JSON):
{
  "titulo_personalizado": "$_directivaTitulo",
  "contenido_markdown": "Formato indentado con guiones (2 espacios por nivel):\\n- Nodo Central\\n  - Rama 1\\n    - Subidea 1.1\\n  - Rama 2\\n    - Subidea 2.1"
}

REGLAS DEL MAPA:
- El nodo central resume el tema transversal de todas las fuentes.
- Entre 4 y 8 ramas principales a partir del nodo central.
- Cada rama con 2 a 5 subnodos. Profundidad máxima: 3 niveles.
- Etiquetas MUY concisas (máximo 6 palabras por nodo).
- Cada línea del markdown es un nodo indentado con "  - ".
- Conecta conceptos de diferentes fuentes cuando sea relevante.
- Solo conceptos de las fuentes. En español.
$_contextoBloque(fuentes)''';

  String _promptCuestionario(List<FuenteEstudio> fuentes) => '''
$_systemInstruction

TAREA: Genera tarjetas de estudio (pregunta/respuesta) a partir de todas las fuentes.

ESQUEMA JSON EXACTO (responde SOLO este JSON):
{
  "titulo_personalizado": "$_directivaTitulo",
  "tarjetas": [
    {"pregunta": "¿Qué establece...?", "respuesta": "Establece que..."}
  ]
}

REGLAS:
- Exactamente 10 tarjetas.
- Las preguntas deben cubrir TODAS las fuentes combinadas, no solo una.
- Preguntas variadas: definiciones, relaciones, causas, consecuencias, comparaciones.
- Respuestas claras y concisas (1-3 frases).
- En español. Solo conceptos de las fuentes.
- Ordena de más sencillo a más difícil.
$_contextoBloque(fuentes)''';

  String _promptPractica(List<FuenteEstudio> fuentes) => '''
$_systemInstruction

TAREA: Genera un test de práctica a partir de todas las fuentes.

ESQUEMA JSON EXACTO (responde SOLO este JSON):
{
  "titulo_personalizado": "$_directivaTitulo",
  "preguntas": [
    {
      "tipo": "opcion_multiple",
      "enunciado": "¿Qué establece...?",
      "opciones": ["A", "B", "C", "D"],
      "respuesta_correcta": "A",
      "explicacion": "Porque..."
    }
  ]
}

REGLAS:
- Exactamente 10 preguntas: 5 de opción múltiple (4 opciones) y 5 de rellenar hueco.
- Cubre TODAS las fuentes combinadas proporcionalmente.
- Opciones verosímiles. Respuestas de hueco: máx. 3 palabras.
- Enunciados claros. Explicaciones de 1-2 frases.
- En español. Solo conceptos de las fuentes.
- Ordena de más sencilla a más difícil.
$_contextoBloque(fuentes)''';

  Future<Map<String, dynamic>> resumirMulti(List<FuenteEstudio> fuentes) async {
    _verificarClave();
    if (fuentes.isEmpty) {
      throw const EstudioIaException('Sin fuentes para resumir.');
    }
    final parts = await _partsMulti(fuentes, _promptResumen(fuentes));
    final texto = await _generarTextoConReintento(parts);
    return _decodificarJsonConReintento(texto);
  }

  Future<Map<String, dynamic>> mapaMentalMulti(
      List<FuenteEstudio> fuentes) async {
    _verificarClave();
    if (fuentes.isEmpty) {
      throw const EstudioIaException('Sin fuentes para el mapa.');
    }
    final parts = await _partsMulti(fuentes, _promptMapaMental(fuentes));
    final texto = await _generarTextoConReintento(parts);
    return _decodificarJsonConReintento(texto);
  }

  Future<Map<String, dynamic>> generarCuestionarioMulti(
      List<FuenteEstudio> fuentes) async {
    _verificarClave();
    if (fuentes.isEmpty) {
      throw const EstudioIaException('Sin fuentes para el cuestionario.');
    }
    final parts = await _partsMulti(fuentes, _promptCuestionario(fuentes));
    final texto = await _generarTextoConReintento(parts);
    return _decodificarJsonConReintento(texto);
  }

  Future<Map<String, dynamic>> generarPracticaMulti(
      List<FuenteEstudio> fuentes) async {
    _verificarClave();
    if (fuentes.isEmpty) {
      throw const EstudioIaException('Sin fuentes para la práctica.');
    }
    final parts = await _partsMulti(fuentes, _promptPractica(fuentes));
    final texto = await _generarTextoConReintento(parts);
    return _decodificarJsonConReintento(texto);
  }

  Future<String> resumir(FuenteEstudio fuente) async {
    final json = await resumirMulti([fuente]);
    return (json['contenido_markdown'] as String?) ?? '';
  }

  Future<MapaMental> mapaMental(FuenteEstudio fuente) async {
    final json = await mapaMentalMulti([fuente]);
    return parsearMarkdownAMapaMental(
        json['contenido_markdown'] as String? ?? '',
        json['titulo_personalizado'] as String? ?? 'Mapa mental');
  }

  MapaMental parsearMarkdownAMapaMental(String markdown, String titulo) {
    final lineas = markdown.split('\n');
    var idx = 0;

    NodoMental? parsearNodo(int nivelEsperado) {
      final hijos = <NodoMental>[];
      while (idx < lineas.length) {
        final linea = lineas[idx];
        final trimmed = linea.trimLeft();
        if (trimmed.isEmpty) {
          idx++;
          continue;
        }
        final espacios = linea.length - trimmed.length;
        final nivel = espacios ~/ 2;
        if (nivel < nivelEsperado) break;
        if (nivel > nivelEsperado) {
          idx++;
          continue;
        }
        final contenido =
            trimmed.startsWith('- ') ? trimmed.substring(2).trim() : trimmed;
        if (contenido.isEmpty) {
          idx++;
          continue;
        }
        idx++;
        final nodoHijos = nivelEsperado < 3
            ? (parsearNodo(nivelEsperado + 1)?.hijos ?? <NodoMental>[])
            : <NodoMental>[];
        hijos.add(NodoMental(
          id: 'n$idx',
          titulo: contenido.length > 40
              ? '${contenido.substring(0, 40)}…'
              : contenido,
          hijos: nodoHijos,
        ));
      }
      return NodoMental(
        id: 'n$idx',
        titulo: '',
        hijos: hijos,
      );
    }

    idx = 0;
    final root = parsearNodo(0);
    return MapaMental(central: titulo, ramas: root?.hijos ?? []);
  }

  Future<List<Map<String, dynamic>>> generarPractica(
      FuenteEstudio fuente) async {
    final json = await generarPracticaMulti([fuente]);
    final preguntas = json['preguntas'];
    if (preguntas is! List || preguntas.isEmpty) {
      throw const EstudioIaException('No se pudieron generar preguntas.');
    }
    return preguntas.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _partsMulti(
    List<FuenteEstudio> fuentes,
    String prompt,
  ) async {
    final parts = <Map<String, dynamic>>[
      {'text': prompt}
    ];
    for (final fuente in fuentes) {
      switch (fuente) {
        case FuenteTexto(:final contenido):
          final recortado = contenido.length > 18000
              ? contenido.substring(0, 18000)
              : contenido;
          parts.add(
              {'text': '\n\n--- FUENTE: ${fuente.titulo} ---\n$recortado'});
        case FuenteArchivo(:final url, :final mimeType):
          final bytes = await _descargar(url);
          parts.add({
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Encode(bytes),
            }
          });
      }
    }
    return parts;
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

  Future<String> _generarTextoConReintento(
    List<Map<String, dynamic>> parts,
  ) async {
    try {
      return await _generarTexto(parts);
    } on EstudioIaException {
      rethrow;
    } catch (e) {
      return await _generarTexto(parts);
    }
  }

  Future<String> _generarTexto(
    List<Map<String, dynamic>> parts,
  ) async {
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
            'response_mime_type': 'application/json',
            'temperature': 0.2,
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

  String? _extraerTexto(Map<String, dynamic>? data) {
    final candidates =
        (data?['candidates'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    if (candidates.isEmpty) return null;
    final content = candidates.first['content'];
    if (content is! Map<String, dynamic>) return null;
    final responseParts = content['parts'] as List<dynamic>?;
    if (responseParts == null || responseParts.isEmpty) return null;
    return responseParts.first['text']?.toString();
  }

  Map<String, dynamic> _decodificarJsonConReintento(String raw) {
    try {
      return _decodificarJson(raw);
    } on EstudioIaException {
      try {
        return _decodificarJson(raw);
      } catch (_) {
        rethrow;
      }
    }
  }

  Map<String, dynamic> _decodificarJson(String raw) {
    var s = raw
        .trim()
        .replaceAll(RegExp(r'^```(json)?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();

    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start != -1 && end > start) {
      s = s.substring(start, end + 1);
    }

    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      throw const EstudioIaException(
          'La IA devolvió un formato inválido. Intenta de nuevo.');
    }

    throw const EstudioIaException('La IA no devolvió un JSON válido.');
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
