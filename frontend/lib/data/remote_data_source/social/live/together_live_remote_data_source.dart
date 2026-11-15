import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../local_data_source/token_storage.dart';
import '../../api/api_client.dart';
import '../../api/sse_parser.dart';
import 'fetch_stream_stub.dart'
    if (dart.library.js_interop) 'fetch_stream_web.dart';

/// Canal en directo de «Con amigos» (`GET /api/v1/together/stream`, SSE,
/// ADR 0047). En el móvil, con Dio (respuesta a trozos, con el token y su
/// renovación de siempre); en la web, con `fetch`, porque Dio no entrega la
/// respuesta hasta el final. Solo aquí se habla de SSE.
class TogetherLiveRemoteDataSource {
  TogetherLiveRemoteDataSource(this._api, this._tokens, {bool? web})
    : _web = web ?? kIsWeb;

  static const path = '/api/v1/together/stream';

  /// El servidor manda un latido cada 25 s: sin nada en 70 s, el canal está
  /// roto aunque la conexión no lo diga.
  static const idleTimeout = Duration(seconds: 70);

  final ApiClient _api;
  final TokenStorage _tokens;
  final bool _web;

  /// Mensajes del canal hasta que se corta (termina o falla). Cancelar la
  /// suscripción cierra la conexión.
  Stream<SseEvent> open() =>
      (_web ? _openWeb() : _openDio()).transform(sseTransformer());

  Stream<List<int>> _openDio() async* {
    final cancel = CancelToken();
    try {
      final response = await _api.dio.get<ResponseBody>(
        path,
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: idleTimeout,
          headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
        ),
      );
      final Stream<Uint8List> body = response.data!.stream;
      yield* body;
    } finally {
      cancel.cancel();
    }
  }

  Stream<List<int>> _openWeb() async* {
    final tokens = await _tokens.read();
    final url = Uri.parse(_api.dio.options.baseUrl).resolve(path);
    yield* fetchStream(url, {
      'Accept': 'text/event-stream',
      if (tokens != null) 'Authorization': 'Bearer ${tokens.accessToken}',
    }).timeout(idleTimeout);
  }
}
