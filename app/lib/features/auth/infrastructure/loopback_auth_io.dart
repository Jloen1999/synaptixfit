// Implementacion real del servidor loopback con dart:io.
// Solo se compila en plataformas nativas (Linux, macOS, Windows).

import 'dart:async';
import 'dart:io';

class LoopbackServer {
  final int port;
  final Future<Uri?> callback;
  final Future<void> Function() close;

  LoopbackServer({
    required this.port,
    required this.callback,
    required this.close,
  });
}

Future<LoopbackServer> iniciarServidorLoopback({int puerto = 0}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, puerto);
  final completer = Completer<Uri?>();

  final subscription = server.listen((request) {
    if (request.uri.path == '/callback') {
      if (!completer.isCompleted) {
        completer.complete(request.uri);
      }
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<!DOCTYPE html><html><head><meta charset="utf-8">'
        '<title>SynaptixFit — Autenticacion</title></head>'
        '<body style="font-family:sans-serif;text-align:center;padding-top:80px;">'
        '<h1>Autenticacion completada</h1>'
        '<p>Ya puedes cerrar esta pestana y volver a la aplicacion.</p>'
        '</body></html>',
      );
      request.response.close();
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.close();
    }
  });

  return LoopbackServer(
    port: server.port,
    callback: completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => null,
    ),
    close: () async {
      await subscription.cancel();
      await server.close(force: true);
    },
  );
}
