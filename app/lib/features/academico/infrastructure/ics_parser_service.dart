import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/env_config.dart';
import '../../../shared/utils/string_utils.dart';
import '../domain/ics_evento.dart';

class IcsParserService {
  static const _diagKeywords = [
    'examen',
    'parcial',
    'quiz',
    'evaluacion',
    'test',
    'final',
    'midterm',
    'exam',
  ];

  static const _entregaKeywords = [
    'entrega',
    'tarea',
    'proyecto',
    'deadline',
    'trabajo',
    'assignment',
    'submission',
  ];

  Future<String> _descargarIcs(String url) async {
    if (EnvConfig.hasR2Worker) {
      final base = EnvConfig.r2WorkerUrl.replaceAll(RegExp(r'/+$'), '');
      final proxyUrl = '$base/_proxy/ics';
      debugPrint('[ICS] Usando proxy: $proxyUrl');
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
      ));
      try {
        final response = await dio.post<String>(
          proxyUrl,
          data: jsonEncode({'url': url}),
          options: Options(
            contentType: 'application/json',
            responseType: ResponseType.plain,
          ),
        );
        final body = response.data;
        if (body == null || body.isEmpty) {
          throw Exception('El proxy devolvió una respuesta vacía');
        }
        debugPrint('[ICS] Proxy OK — ${body.length} chars');
        return body;
      } on DioException catch (e) {
        debugPrint('[ICS] Proxy error: ${e.type} — ${e.message}');
        debugPrint(
            '[ICS] Response: ${e.response?.statusCode} ${e.response?.data}');
        final serverMsg = _extraerMensajeProxy(e);
        if (serverMsg != null) throw Exception(serverMsg);
        rethrow;
      }
    }

    debugPrint('[ICS] Descarga directa: $url');
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      maxRedirects: 5,
      headers: {
        'User-Agent': 'SynaptixFit/1.0 (Calendar Sync)',
        'Accept': '*/*',
      },
    ));
    final response = await dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final body = response.data;
    if (body == null || body.isEmpty) {
      throw Exception('El servidor devolvió una respuesta vacía');
    }
    debugPrint('[ICS] Directa OK — ${body.length} chars');
    return body;
  }

  String? _extraerMensajeProxy(DioException e) {
    final data = e.response?.data;
    if (data is String && data.isNotEmpty) {
      try {
        final json = jsonDecode(data);
        if (json is Map) {
          return json['error'] as String? ?? json['detail'] as String?;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<IcsParseResult> parsearYValidar(
    String url,
    String asignaturaNombre,
    String? asignaturaCodigo,
  ) async {
    final raw = await _descargarIcs(url);

    final bloques = _extraerBloquesVevent(raw);
    final eventos = <IcsEvento>[];

    for (final bloque in bloques) {
      final props = _parsearPropiedades(bloque);
      if (props['DTSTART'] == null) continue;

      final uid = props['UID'] ??
          _generarUidFallback(
            props['SUMMARY'] ?? '',
            props['DTSTART']!,
          );
      final summary = props['SUMMARY'] ?? 'Sin titulo';
      final tipo = _clasificarTipo(summary);
      final dtStart = _parsearDtStart(props['DTSTART']!);
      final dtEnd = props['DTEND'] != null
          ? _parsearDtStart(props['DTEND']!)
          : dtStart.add(const Duration(hours: 1));
      final coincide = _coincide(summary, asignaturaNombre, asignaturaCodigo);

      eventos.add(IcsEvento(
        uid: uid,
        titulo: summary,
        tipo: tipo,
        dtStart: dtStart,
        dtEnd: dtEnd,
        descripcion: props['DESCRIPTION'],
        ubicacion: props['LOCATION'],
        coincideAsignatura: coincide,
      ));
    }

    final coincidentes = eventos.where((e) => e.coincideAsignatura).toList();

    late final EstadoCoincidencia estado;
    if (eventos.isEmpty || coincidentes.isEmpty) {
      estado = EstadoCoincidencia.ninguna;
    } else if (coincidentes.length == eventos.length) {
      estado = EstadoCoincidencia.completa;
    } else {
      estado = EstadoCoincidencia.parcial;
    }

    return IcsParseResult(
      todosLosEventos: eventos,
      eventosCoincidentes: coincidentes,
      estado: estado,
    );
  }

  List<String> _extraerBloquesVevent(String raw) {
    final bloques = <String>[];
    final lineas = LineSplitter.split(raw).toList();
    var inside = false;
    final buffer = StringBuffer();

    for (final linea in lineas) {
      final trimmed = linea.trim();
      if (trimmed.toUpperCase() == 'BEGIN:VEVENT') {
        inside = true;
        buffer.clear();
        buffer.writeln(trimmed);
      } else if (trimmed.toUpperCase() == 'END:VEVENT') {
        buffer.writeln(trimmed);
        bloques.add(buffer.toString());
        inside = false;
      } else if (inside) {
        buffer.writeln(trimmed);
      }
    }

    return bloques;
  }

  Map<String, String> _parsearPropiedades(String bloque) {
    final props = <String, String>{};
    final lineas = LineSplitter.split(bloque);

    String? currentKey;

    for (final line in lineas) {
      if (line.startsWith(' ') || line.startsWith('\t')) {
        if (currentKey != null) {
          props[currentKey] = (props[currentKey] ?? '') + line.trim();
        }
        continue;
      }

      final colonIdx = line.indexOf(':');
      if (colonIdx == -1) continue;

      final rawKey = line.substring(0, colonIdx);
      final value = line.substring(colonIdx + 1);

      final keyParts = rawKey.split(';');
      final key = keyParts.first.toUpperCase();

      props[key] = value;
      currentKey = key;
    }

    return props;
  }

  String _clasificarTipo(String summary) {
    final lower = summary.toLowerCase();
    for (final kw in _diagKeywords) {
      if (lower.contains(kw)) return 'examen';
    }
    for (final kw in _entregaKeywords) {
      if (lower.contains(kw)) return 'entrega';
    }
    return 'clase';
  }

  bool _coincide(String summary, String nombre, String? codigo) {
    final sumNorm = normalizeSearch(summary);
    final nomNorm = normalizeSearch(nombre);
    if (sumNorm.contains(nomNorm)) return true;
    if (codigo != null && codigo.isNotEmpty) {
      if (sumNorm.contains(normalizeSearch(codigo))) return true;
    }
    final palabras =
        nomNorm.split(RegExp(r'\s+')).where((p) => p.length > 2).toList();
    if (palabras.isNotEmpty) {
      final matches = palabras.where((p) => sumNorm.contains(p)).length;
      if (matches / palabras.length >= 0.6) return true;
    }
    return false;
  }

  DateTime _parsearDtStart(String raw) {
    final colonIdx = raw.indexOf(':');
    final value = colonIdx != -1 ? raw.substring(colonIdx + 1) : raw;

    final upper = raw.toUpperCase();

    if (upper.contains('VALUE=DATE')) {
      final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length >= 8) {
        final year = int.parse(clean.substring(0, 4));
        final month = int.parse(clean.substring(4, 6));
        final day = int.parse(clean.substring(6, 8));
        return DateTime(year, month, day, 9, 0);
      }
    }

    if (upper.contains('TZID=')) {
      final tzidx = upper.indexOf('TZID=');
      final afterTzid = upper.substring(tzidx + 5);
      final colonAfterTzid = afterTzid.indexOf(':');
      final dtValue = colonAfterTzid != -1
          ? afterTzid.substring(colonAfterTzid + 1)
          : afterTzid;
      return _parsearDtValue(dtValue, isUtc: false);
    }

    if (value.toUpperCase().endsWith('Z')) {
      return _parsearDtValue(value, isUtc: true);
    }

    return _parsearDtValue(value, isUtc: false);
  }

  DateTime _parsearDtValue(String raw, {required bool isUtc}) {
    final clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length >= 14) {
      final year = int.parse(clean.substring(0, 4));
      final month = int.parse(clean.substring(4, 6));
      final day = int.parse(clean.substring(6, 8));
      final hour = int.parse(clean.substring(8, 10));
      final minute = int.parse(clean.substring(10, 12));
      final second =
          clean.length >= 14 ? int.parse(clean.substring(12, 14)) : 0;
      if (isUtc) {
        return DateTime.utc(year, month, day, hour, minute, second);
      }
      return DateTime(year, month, day, hour, minute, second);
    }

    if (clean.length >= 8) {
      final year = int.parse(clean.substring(0, 4));
      final month = int.parse(clean.substring(4, 6));
      final day = int.parse(clean.substring(6, 8));
      return DateTime(year, month, day, 9, 0);
    }

    return DateTime.now();
  }

  String _generarUidFallback(String summary, String dtStart) {
    final raw = '$summary$dtStart';
    final bytes = utf8.encode(raw);
    var hash = 0;
    for (final b in bytes) {
      hash = ((hash << 5) - hash) + b;
      hash |= 0;
    }
    return 'sxf-${hash.abs().toRadixString(16)}';
  }
}
