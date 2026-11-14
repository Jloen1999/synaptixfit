import 'package:flutter_bloc/flutter_bloc.dart';

/// Cambios que se quitan de la vista al momento y se hacen de verdad al
/// cerrarse su aviso con «Deshacer» (borrar una entrega o un entreno de
/// carrera, descartar una sugerencia; vocabulario §4: lo reversible no
/// pregunta). Si el bloc se cierra antes, lo aplazado se hace igual: salir de
/// la pantalla también cierra el aviso (`showUndoSnack`), así que su
/// «Deshacer» nunca queda sin efecto.
mixin DeferredCommitMixin<S> on BlocBase<S> {
  final Set<String> _deferred = {};

  /// Hace el cambio aplazado de [id] (llama al caso de uso).
  Future<void> commitDeferred(String id);

  /// Aplaza el cambio de [id]; `false` si ya estaba aplazado.
  bool defer(String id) => _deferred.add(id);

  /// ¿Está [id] quitado de la vista a la espera de su aviso?
  bool isDeferred(String id) => _deferred.contains(id);

  /// «Deshacer» o confirmación: lo saca de la espera. `false` si ya no estaba
  /// (deshecho, confirmado o hecho al cerrar), y entonces no hay que hacer nada.
  bool release(String id) => _deferred.remove(id);

  @override
  Future<void> close() async {
    final pending = [..._deferred];
    _deferred.clear();
    try {
      await Future.wait(pending.map(commitDeferred));
    } finally {
      await super.close();
    }
  }
}
