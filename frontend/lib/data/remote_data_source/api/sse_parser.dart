import 'dart:async';
import 'dart:convert';

/// Un mensaje de Server-Sent Events: su nombre (`event:`) y sus datos
/// (`data:`, varias líneas unidas con salto de línea).
class SseEvent {
  const SseEvent(this.event, this.data);

  final String event;
  final String data;
}

/// Convierte los bytes de una respuesta `text/event-stream` en mensajes
/// (formato de WHATWG: líneas `campo: valor` y una línea en blanco al final de
/// cada mensaje). Los comentarios (`: ping`, el latido) se ignoran.
///
/// Sin generadores `async*`: un `await for` no se entera de que se canceló la
/// suscripción hasta el siguiente mensaje, y la conexión seguiría abierta.
StreamTransformer<List<int>, SseEvent> sseTransformer() =>
    StreamTransformer.fromBind((bytes) {
      var event = 'message';
      final data = <String>[];
      return utf8.decoder
          .bind(bytes)
          .transform(const LineSplitter())
          .transform(
            StreamTransformer<String, SseEvent>.fromHandlers(
              handleData: (line, sink) {
                if (line.isEmpty) {
                  if (data.isNotEmpty) sink.add(SseEvent(event, data.join('\n')));
                  event = 'message';
                  data.clear();
                  return;
                }
                if (line.startsWith(':')) return;
                final colon = line.indexOf(':');
                final field = colon < 0 ? line : line.substring(0, colon);
                var value = colon < 0 ? '' : line.substring(colon + 1);
                if (value.startsWith(' ')) value = value.substring(1);
                switch (field) {
                  case 'event':
                    event = value;
                  case 'data':
                    data.add(value);
                }
              },
            ),
          );
    });
