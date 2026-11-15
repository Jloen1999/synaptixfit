import '../../domain/use_cases/social/together_live/is_together_live_connected_use_case.dart';

/// Consulta periódica de respaldo de «Con amigos» (ADR 0047): con el canal en
/// directo conectado los cambios llegan solos, así que la consulta de siempre
/// solo lee cada [slowPoll]; si el canal cae, vuelve a su ritmo normal.
mixin LivePollMixin {
  /// Con el canal conectado, cada cuánto se lee como mucho.
  static const slowPoll = Duration(minutes: 1);

  IsTogetherLiveConnectedUseCaseContract? get liveConnected;

  DateTime? _lastRead;

  /// Se salta esta consulta: el canal está conectado y se leyó hace poco.
  bool skipPoll([DateTime? now]) {
    final last = _lastRead;
    return (liveConnected?.call() ?? false) &&
        last != null &&
        (now ?? DateTime.now()).difference(last) < slowPoll;
  }

  void markRead([DateTime? now]) => _lastRead = now ?? DateTime.now();
}
