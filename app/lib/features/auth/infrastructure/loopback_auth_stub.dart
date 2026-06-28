// Stub para plataformas sin dart:io (web).
// El helper real esta en loopback_auth_io.dart.

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
  throw UnimplementedError(
      'El servidor loopback no esta disponible en esta plataforma');
}
