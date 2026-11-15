import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/enums/data_topic.dart';
import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../../domain/use_cases/social/together/decline_workout_together_use_case.dart';
import '../../../../../../domain/use_cases/social/together/get_workout_together_use_case.dart';
import '../../../../../../domain/use_cases/social/together/join_workout_together_use_case.dart';
import '../../../../../../domain/use_cases/social/together/leave_workout_together_use_case.dart';
import '../../../../../../domain/use_cases/social/together/start_workout_together_use_case.dart';
import '../../../../../../domain/use_cases/social/together_live/is_together_live_connected_use_case.dart';
import '../../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../../mixins/data_change_refresh_mixin.dart';
import '../../../../../mixins/live_poll_mixin.dart';

part 'workout_together_bloc.freezed.dart';
part 'workout_together_event.dart';
part 'workout_together_state.dart';

/// Detalle y pantalla de espera de «Entrenamos juntos» (ADR 0044 y 0047).
/// Vuelve a leer en cuanto el canal en directo avisa
/// ([DataTopic.workoutTogether]) y, de respaldo, cada [pollInterval] (más
/// despacio con el canal conectado). «Empezar» lo puede pulsar cualquiera de
/// dentro y empieza para todos; si lo pulsa otra persona mientras esta pantalla
/// está abierta, se entra sola en la sesión en vivo de siempre ([openSession]).
class WorkoutTogetherBloc
    extends Bloc<WorkoutTogetherEvent, WorkoutTogetherState>
    with DataChangeRefreshMixin, LivePollMixin {
  WorkoutTogetherBloc({
    required this._get,
    required this._join,
    required this._decline,
    required this._leave,
    required this._start,
    this._watchChanges,
    this.liveConnected,
    this.pollInterval = const Duration(seconds: 15),
  }) : super(const WorkoutTogetherState()) {
    on<WorkoutTogetherStarted>(_onStarted);
    on<WorkoutTogetherPolled>(_onPolled);
    on<WorkoutTogetherJoined>(_onJoined);
    on<WorkoutTogetherDeclined>(_onDeclined);
    on<WorkoutTogetherLeft>(_onLeft);
    on<WorkoutTogetherStartRequested>(_onStart);
  }

  final GetWorkoutTogetherUseCaseContract _get;
  final JoinWorkoutTogetherUseCaseContract _join;
  final DeclineWorkoutTogetherUseCaseContract _decline;
  final LeaveWorkoutTogetherUseCaseContract _leave;
  final StartWorkoutTogetherUseCaseContract _start;
  final WatchDataChangesUseCaseContract? _watchChanges;
  @override
  final IsTogetherLiveConnectedUseCaseContract? liveConnected;
  final Duration pollInterval;
  Timer? _timer;

  /// Ya se abrió la sesión desde esta pantalla: no se vuelve a abrir sola.
  bool _entered = false;

  String get _id => state.id!;

  Future<void> _onStarted(
    WorkoutTogetherStarted event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    emit(
      state.copyWith(
        id: event.id,
        status: WorkoutTogetherStatus.loading,
        error: null,
      ),
    );
    final result = await _get(event.id);
    if (result is Success) markRead();
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: WorkoutTogetherStatus.ready,
        workout: value,
      ),
      Failure(:final error) => state.copyWith(
        status: WorkoutTogetherStatus.failure,
        error: error,
      ),
    });
    _timer?.cancel();
    _timer = Timer.periodic(
      pollInterval,
      (_) => add(const WorkoutTogetherEvent.polled()),
    );
    final watch = _watchChanges;
    if (watch != null) {
      watchDataChanges(
        watch,
        topics: const {DataTopic.workoutTogether},
        onChanged: const WorkoutTogetherEvent.polled(live: true),
      );
    }
  }

  /// Lectura silenciosa: un fallo de red no cambia lo que se ve. Si otra
  /// persona acaba de empezar y ya tengo mi sesión, se entra en ella.
  Future<void> _onPolled(
    WorkoutTogetherPolled event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    if (state.id == null || state.busy) return;
    if (!event.live && skipPoll()) return;
    final result = await _get(_id);
    if (result case Success(:final value)) {
      markRead();
      final before = state.workout;
      emit(state.copyWith(status: WorkoutTogetherStatus.ready, workout: value));
      final session = value.mySessionId;
      final finished =
          value.members.where((m) => m.me).firstOrNull?.state ==
          WorkoutMemberState.finished;
      if (!_entered &&
          before != null &&
          !before.started &&
          value.started &&
          value.joined &&
          value.today &&
          !finished &&
          session != null) {
        _entered = true;
        emit(state.copyWith(openSession: session, startedByOther: true));
        emit(state.copyWith(openSession: null, startedByOther: false));
      }
    }
  }

  Future<void> _onJoined(
    WorkoutTogetherJoined event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _join(_id);
    emit(switch (result) {
      Success(:final value) => state.copyWith(busy: false, workout: value),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(actionError: null));
  }

  Future<void> _onDeclined(
    WorkoutTogetherDeclined event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _decline(_id);
    emit(switch (result) {
      Success() => state.copyWith(busy: false, closed: true),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(actionError: null));
  }

  Future<void> _onLeft(
    WorkoutTogetherLeft event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _leave(_id);
    emit(switch (result) {
      Success() => state.copyWith(busy: false, left: true),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(left: false, actionError: null));
  }

  Future<void> _onStart(
    WorkoutTogetherStartRequested event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _start(_id);
    if (result is Success) _entered = true;
    emit(switch (result) {
      Success(:final value) => state.copyWith(busy: false, openSession: value),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(openSession: null, actionError: null));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
