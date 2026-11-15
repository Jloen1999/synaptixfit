import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Error HTTP del canal en la web (p. ej. 401 con el token caducado).
class FetchStreamStatusError implements Exception {
  const FetchStreamStatusError(this.status);

  final int status;

  @override
  String toString() => 'FetchStreamStatusError($status)';
}

/// En la web Dio usa XMLHttpRequest, que no entrega la respuesta hasta el
/// final: un canal SSE no llegaría nunca. `fetch` sí la entrega a trozos
/// (ReadableStream) y, a diferencia de `EventSource`, deja mandar la cabecera
/// `Authorization` (el token no va en la dirección). ADR 0047.
///
/// Dejar de escuchar corta la conexión al momento (`AbortController`): por eso
/// no es un generador `async*`, que esperaría al siguiente trozo para salir.
Stream<List<int>> fetchStream(Uri url, Map<String, String> headers) {
  final abort = web.AbortController();
  late final StreamController<List<int>> out;

  Future<void> read() async {
    try {
      final init = web.RequestInit(
        method: 'GET',
        headers: headers.jsify()! as web.HeadersInit,
        cache: 'no-store',
        signal: abort.signal,
      );
      final response = await web.window
          .fetch(url.toString().toJS, init)
          .toDart;
      final body = response.body;
      if (!response.ok || body == null) {
        throw FetchStreamStatusError(response.status);
      }
      final reader = body.getReader() as web.ReadableStreamDefaultReader;
      while (!out.isClosed) {
        final chunk = await reader.read().toDart;
        if (chunk.done) break;
        final value = chunk.value;
        if (value != null && !out.isClosed) {
          out.add((value as JSUint8Array).toDart);
        }
      }
    } catch (error, stackTrace) {
      // Cortar a propósito (dejar de escuchar) también llega aquí: no es un
      // fallo que contar.
      if (!out.isClosed) out.addError(error, stackTrace);
    } finally {
      if (!out.isClosed) await out.close();
    }
  }

  out = StreamController<List<int>>(
    onListen: () => unawaited(read()),
    onCancel: () {
      abort.abort();
      return out.close();
    },
  );
  return out.stream;
}
