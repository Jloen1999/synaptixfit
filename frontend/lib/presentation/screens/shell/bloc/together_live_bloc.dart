import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/data_topic.dart';
import '../../../../domain/enums/together_enums.dart';
import '../../../../domain/models/result/app_result.dart';
import '../../../../domain/models/result/result.dart';
import '../../../../domain/models/social/together.dart';
import '../../../../domain/models/social/together_live.dart';
import '../../../../domain/use_cases/social/together/get_together_overview_use_case.dart';
import '../../../../domain/use_cases/social/together/get_workout_together_use_case.dart';
import '../../../../domain/use_cases/social/together_live/watch_together_live_use_case.dart';
import '../../../../domain/use_cases/sync/publish_data_changes_use_case.dart';

part 'together_live_bloc.freezed.dart';
part 'together_live_event.dart';
part 'together_live_state.dart';

/// Canal en directo de «Con amigos» (ADR 0047) mientras la app está en primer
/// plano: lo abre al entrar en el armazón, lo cierra en segundo plano (y al
/// cerrarse el bloc, al cerrar sesión) y, si se corta, lo vuelve a abrir con
/// espera creciente. Cada aviso se publica como cambio de datos para que la
/// sala, el entreno juntos, «Con amigos» y la sesión en vivo vuelvan a leer al
/// momento. Además avisa cuando un amigo empieza un entreno juntos en el que
/// estoy y, al abrir la app, lleva una vez al entreno o la sala en marcha.
class TogetherLiveBloc extends Bloc<TogetherLiveEvent, TogetherLiveState> {
  TogetherLiveBloc({
    required this._watch,
    required this._publish,
    required this._getWorkout,
    required this._overview,
    this.firstRetry = const Duration(seconds: 2),
    this.maxRetry = const Duration(minutes: 1),
  }) : _retry = firstRetry,
       super(const TogetherLiveState()) {
    on<TogetherLiveStarted>(_onStarted);
    on<TogetherLiveForegrounded>(_onForegrounded);
    on<TogetherLiveBackgrounded>(_onBackgrounded);
    on<TogetherLiveSignalReceived>(_onSignal);
    on<TogetherLiveDropped>(_onDropped);
    on<TogetherLiveReconnectDue>((_, _) => _connect());
  }

  final WatchTogetherLiveUseCaseContract _watch;
  final PublishDataChangesUseCaseContract _publish;
  final GetWorkoutTogetherUseCaseContract _getWorkout;
  final GetTogetherOverviewUseCaseContract _overview;

  /// Primera espera tras un corte; se dobla en cada intento hasta [maxRetry].
  final Duration firstRetry;
  final Duration maxRetry;

  Duration _retry;
  StreamSubscription<AppResult<TogetherLiveSignal>>? _subscription;
  Timer? _retryTimer;
  bool _foreground = false;
  bool _launchChecked = false;

  /// Ya hubo una conexión: la siguiente es una reconexión y puede haberse
  /// perdido algún aviso mientras tanto.
  bool _wasConnected = false;

  /// Lo último visto de cada entreno juntos: si había empezado y si estaba en
  /// pausa. Así se sabe cuándo alguien acaba de empezar o de pausar.
  final _known = <String, ({bool started, bool paused})>{};

  Future<void> _onStarted(
    TogetherLiveStarted event,
    Emitter<TogetherLiveState> emit,
  ) async {
    _foreground = true;
    _connect();
    if (_launchChecked) return;
    _launchChecked = true;
    await _checkLaunch(emit);
  }

  void _onForegrounded(
    TogetherLiveForegrounded event,
    Emitter<TogetherLiveState> emit,
  ) {
    if (_foreground) return;
    _foreground = true;
    _retry = firstRetry;
    _connect();
  }

  void _onBackgrounded(
    TogetherLiveBackgrounded event,
    Emitter<TogetherLiveState> emit,
  ) {
    _foreground = false;
    _disconnect();
    emit(state.copyWith(connected: false));
  }

  void _connect() {
    if (!_foreground || _subscription != null || isClosed) return;
    _retryTimer?.cancel();
    _subscription = _watch().listen(
      (result) => add(switch (result) {
        Success(:final value) => TogetherLiveEvent.signalReceived(value),
        Failure() => const TogetherLiveEvent.dropped(),
      }),
      onDone: () {
        if (!isClosed) add(const TogetherLiveEvent.dropped());
      },
    );
  }

  void _disconnect() {
    _retryTimer?.cancel();
    _retryTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void _onDropped(TogetherLiveDropped event, Emitter<TogetherLiveState> emit) {
    _disconnect();
    emit(state.copyWith(connected: false));
    if (!_foreground) return;
    _retryTimer = Timer(_retry, () {
      if (!isClosed) add(const TogetherLiveEvent.reconnectDue());
    });
    _retry = Duration(
      milliseconds: math.min(
        _retry.inMilliseconds * 2,
        maxRetry.inMilliseconds,
      ),
    );
  }

  Future<void> _onSignal(
    TogetherLiveSignalReceived event,
    Emitter<TogetherLiveState> emit,
  ) async {
    final signal = event.signal;
    if (signal.topic == TogetherLiveTopic.connected) {
      _retry = firstRetry;
      emit(state.copyWith(connected: true));
      // Tras un corte o al volver del segundo plano pudo perderse algún aviso:
      // las pantallas abiertas leen otra vez una vez.
      if (_wasConnected) {
        _publish({...DataTopic.live, DataTopic.social});
      }
      _wasConnected = true;
      return;
    }
    _publish(signal.dataTopics);
    final id = signal.id;
    if (signal.topic == TogetherLiveTopic.workout && id != null) {
      await _checkWorkout(id, emit);
    }
  }

  /// Lee el entreno avisado para saber si alguien acaba de empezar o pausar.
  Future<void> _checkWorkout(String id, Emitter<TogetherLiveState> emit) async {
    final result = await _getWorkout(id);
    final workout = result.valueOrNull;
    if (workout == null) return;
    final before = _known[id];
    _known[id] = (started: workout.started, paused: workout.paused);
    if (before == null) return;
    if (before.started != workout.started || before.paused != workout.paused) {
      // La barra de sesión abierta y Entreno ven la sesión nueva o su pausa.
      _publish(const {DataTopic.training});
    }
    final sessionId = workout.mySessionId;
    final byOther =
        workout.startedBy != null && workout.startedBy!.id != workout.myId;
    if (!before.started &&
        workout.started &&
        workout.today &&
        workout.joined &&
        sessionId != null &&
        byOther) {
      emit(
        state.copyWith(
          startedByFriend: TogetherLiveStart(
            workoutId: workout.id,
            sessionId: sessionId,
            name: workout.startedBy!.name,
          ),
        ),
      );
      emit(state.copyWith(startedByFriend: null));
    }
  }

  /// Al abrir la app: si estoy en un entreno juntos o una sala en marcha, se
  /// abre (una vez por apertura). También aprende el estado de los entrenos
  /// de hoy para detectar después quién empieza.
  Future<void> _checkLaunch(Emitter<TogetherLiveState> emit) async {
    final overview = (await _overview()).valueOrNull;
    if (overview == null) return;
    for (final w in overview.workouts) {
      _known[w.id] = (started: w.started, paused: w.paused);
    }
    final workout = overview.workouts.where(_running).firstOrNull;
    final room = overview.studyRooms
        .where(
          (r) =>
              r.joined &&
              (r.phase == StudyRoomPhase.focus ||
                  r.phase == StudyRoomPhase.rest),
        )
        .firstOrNull;
    final open = workout != null
        ? TogetherLiveOpen.session(workout.mySessionId!)
        : room != null
        ? TogetherLiveOpen.studyRoom(room.id)
        : null;
    if (open == null) return;
    emit(state.copyWith(openOnLaunch: open));
    emit(state.copyWith(openOnLaunch: null));
  }

  /// Entreno juntos de hoy ya empezado, en el que estoy y no he terminado.
  static bool _running(WorkoutTogether w) {
    final me = w.members.where((m) => m.me).firstOrNull;
    return w.today &&
        w.joined &&
        w.started &&
        w.mySessionId != null &&
        me?.state != WorkoutMemberState.finished;
  }

  @override
  Future<void> close() {
    _disconnect();
    return super.close();
  }
}
