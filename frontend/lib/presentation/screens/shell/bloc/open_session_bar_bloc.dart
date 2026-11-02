import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/data_topic.dart';
import '../../../../domain/models/training/session.dart';
import '../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../domain/use_cases/training/get_open_sessions_use_case.dart';
import '../../../mixins/data_change_refresh_mixin.dart';

part 'open_session_bar_bloc.freezed.dart';
part 'open_session_bar_event.dart';
part 'open_session_bar_state.dart';

/// Sesión de entreno abierta (en pausa o en curso) para la barra «Volver» del
/// armazón. Se refresca con cada cambio de entrenamiento; las abandonadas
/// (más de 6 h) no se muestran: Entreno ya las ofrece terminar o descartar.
class OpenSessionBarBloc extends Bloc<OpenSessionBarEvent, OpenSessionBarState>
    with DataChangeRefreshMixin {
  OpenSessionBarBloc({
    required this._getOpenSessions,
    required this._watchDataChanges,
  }) : super(const OpenSessionBarState()) {
    on<OpenSessionBarStarted>((_, emit) async {
      watchDataChanges(
        _watchDataChanges,
        topics: const {DataTopic.training},
        onChanged: const OpenSessionBarEvent.refreshed(),
      );
      await _load(emit);
    });
    on<OpenSessionBarRefreshed>((_, emit) => _load(emit));
  }

  final GetOpenSessionsUseCaseContract _getOpenSessions;
  final WatchDataChangesUseCaseContract _watchDataChanges;

  Future<void> _load(Emitter<OpenSessionBarState> emit) async {
    final result = await _getOpenSessions();
    // Sin conexión se deja lo que había: la barra no es imprescindible.
    final open = result.valueOrNull;
    if (open == null) return;
    emit(
      OpenSessionBarState(
        session: open.where((o) => !o.stale).firstOrNull?.session,
      ),
    );
  }
}
