import '../models/result/app_result.dart';
import '../models/social/together_live.dart';

/// Canal en directo de «Con amigos» (ADR 0047). [watch] abre la conexión al
/// escucharlo y la cierra al cancelar; si se corta, entrega un fallo o
/// termina, y quien escucha decide cuándo volver a abrirla.
abstract interface class TogetherLiveRepositoryContract {
  Stream<AppResult<TogetherLiveSignal>> watch();

  /// Hay un canal abierto y conectado ahora mismo.
  bool get connected;
}
