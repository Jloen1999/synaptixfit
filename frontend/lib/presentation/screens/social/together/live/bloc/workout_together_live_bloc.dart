import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/enums/data_topic.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../../domain/use_cases/social/together/find_workout_together_by_session_use_case.dart';
import '../../../../../../domain/use_cases/social/together_live/is_together_live_connected_use_case.dart';
import '../../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../../mixins/data_change_refresh_mixin.dart';
import '../../../../../mixins/live_poll_mixin.dart';

part 'workout_together_live_bloc.freezed.dart';
part 'workout_together_live_event.dart';
part 'workout_together_live_state.dart';

/// Quién lleva qué en «Entrenamos juntos» dentro de la sesión en vivo y su
/// resumen (ADR 0044), con la hora de inicio común y la pausa del grupo
/// (ADR 0047). Si la sesión no es de entrenar juntos no pinta nada y no vuelve
/// a preguntar. Si lo es y es de hoy, lee otra vez en cuanto el canal en
/// directo avisa de un cambio ([DataTopic.workoutTogether]) y, de respaldo,
/// cada [pollInterval] (más despacio con el canal conectado). Un fallo de red
/// no cambia lo que se ve ni toca la sesión ni sus borradores.
class WorkoutTogetherLiveBloc
    extends Bloc<WorkoutTogetherLiveEvent, WorkoutTogetherLiveState>
    with DataChangeRefreshMixin, LivePollMixin {
  WorkoutTogetherLiveBloc({
    required this._find,
    this._watchChanges,
    this.liveConnected,
    this.pollInterval = const Duration(seconds: 12),
  }) : super(const WorkoutTogetherLiveState()) {
    on<WorkoutTogetherLiveStarted>(_onStarted);
    on<WorkoutTogetherLivePolled>(_onPolled);
  }

  final FindWorkoutTogetherBySessionUseCaseContract _find;
  final WatchDataChangesUseCaseContract? _watchChanges;
  @override
  final IsTogetherLiveConnectedUseCaseContract? liveConnected;
  final Duration pollInterval;
  Timer? _timer;

  Future<void> _onStarted(
    WorkoutTogetherLiveStarted event,
    Emitter<WorkoutTogetherLiveState> emit,
  ) async {
    emit(state.copyWith(sessionId: event.sessionId));
    await _read(emit);
    final workout = state.workout;
    if (event.poll && workout != null && workout.today) {
      _timer?.cancel();
      _timer = Timer.periodic(
        pollInterval,
        (_) => add(const WorkoutTogetherLiveEvent.polled()),
      );
      final watch = _watchChanges;
      if (watch != null) {
        watchDataChanges(
          watch,
          topics: const {DataTopic.workoutTogether},
          onChanged: const WorkoutTogetherLiveEvent.polled(live: true),
        );
      }
    }
  }

  Future<void> _onPolled(
    WorkoutTogetherLivePolled event,
    Emitter<WorkoutTogetherLiveState> emit,
  ) async {
    if (!event.live && skipPoll()) return;
    await _read(emit);
  }

  Future<void> _read(Emitter<WorkoutTogetherLiveState> emit) async {
    final id = state.sessionId;
    if (id == null) return;
    final result = await _find(id);
    if (result case Success(:final value)) {
      markRead();
      emit(state.copyWith(loaded: true, workout: value));
      if (value == null) _timer?.cancel();
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
