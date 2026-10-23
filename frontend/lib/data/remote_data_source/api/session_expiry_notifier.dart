import 'dart:async';

/// Avisa cuando la sesión ha caducado y no se ha podido renovar.
class SessionExpiryNotifier {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() => _controller.add(null);
}
