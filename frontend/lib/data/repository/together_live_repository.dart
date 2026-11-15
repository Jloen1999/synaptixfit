import 'dart:async';
import 'dart:convert';

import '../../domain/models/result/app_result.dart';
import '../../domain/models/social/together_live.dart';
import '../../domain/repositories/together_live_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/api/sse_parser.dart';
import '../remote_data_source/social/live/together_live_remote_data_source.dart';

/// Implementa [TogetherLiveRepositoryContract] con
/// [TogetherLiveRemoteDataSource]: traduce `ready` y `change` a
/// [TogetherLiveSignal] y lleva la cuenta de si el canal está conectado.
class TogetherLiveRepository implements TogetherLiveRepositoryContract {
  TogetherLiveRepository(this._remote);

  final TogetherLiveRemoteDataSource _remote;
  int _open = 0;

  @override
  bool get connected => _open > 0;

  @override
  Stream<AppResult<TogetherLiveSignal>> watch() =>
      RepositoryErrorHandler.guardStream(_signals);

  /// Con un controlador y no con `async*`: cancelar cierra la conexión al
  /// momento (un `await for` esperaría al siguiente mensaje).
  Stream<TogetherLiveSignal> _signals() {
    var counted = false;
    void release() {
      if (counted) {
        counted = false;
        _open--;
      }
    }

    StreamSubscription<TogetherLiveSignal?>? source;
    late final StreamController<TogetherLiveSignal> out;
    out = StreamController<TogetherLiveSignal>(
      onListen: () {
        // `map` entrega como error lo que no se pueda leer (JSON roto).
        source = _remote
            .open()
            .map(_toSignal)
            .listen(
              (signal) {
                if (signal == null) return;
                if (signal.topic == TogetherLiveTopic.connected && !counted) {
                  counted = true;
                  _open++;
                }
                out.add(signal);
              },
              onError: (Object error, StackTrace stackTrace) {
                release();
                out.addError(error, stackTrace);
              },
              onDone: () {
                release();
                unawaited(out.close());
              },
            );
      },
      onCancel: () {
        release();
        return source?.cancel();
      },
    );
    return out.stream;
  }

  /// `ready` → conectado; `change` → `{type, id}`. Lo que no se entienda (una
  /// versión del servidor más nueva) se ignora.
  static TogetherLiveSignal? _toSignal(SseEvent event) {
    if (event.event == 'ready') {
      return const TogetherLiveSignal(TogetherLiveTopic.connected);
    }
    if (event.event != 'change') return null;
    final json = jsonDecode(event.data);
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final topic = switch (json['type']) {
      'studyRoom' => TogetherLiveTopic.studyRoom,
      'workout' => TogetherLiveTopic.workout,
      'together' => TogetherLiveTopic.together,
      _ => null,
    };
    if (topic == null || id is! String) return null;
    return TogetherLiveSignal(topic, id);
  }
}
