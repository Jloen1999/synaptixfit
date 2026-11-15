import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/data_topic.dart';
import '../../../../domain/enums/together_enums.dart';
import '../../../../domain/errors/app_error.dart';
import '../../../../domain/models/reminders/timer_alert.dart';
import '../../../../domain/models/result/result.dart';
import '../../../../domain/models/social/together.dart';
import '../../../../domain/use_cases/reminders/cancel_timer_alert_use_case.dart';
import '../../../../domain/use_cases/reminders/schedule_timer_alert_use_case.dart';
import '../../../../domain/use_cases/social/together/get_study_room_use_case.dart';
import '../../../../domain/use_cases/social/together_live/is_together_live_connected_use_case.dart';
import '../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../mixins/data_change_refresh_mixin.dart';
import '../../../mixins/live_poll_mixin.dart';

part 'study_room_bar_bloc.freezed.dart';
part 'study_room_bar_event.dart';
part 'study_room_bar_state.dart';

/// Textos (ya traducidos) del aviso de fin de fase de la sala.
class StudyRoomAlertTexts {
  const StudyRoomAlertTexts({
    required this.title,
    required this.focusEndBody,
    required this.breakEndBody,
    required this.channelName,
  });

  final String title;

  /// «Fin de la concentración · ronda 1 de 2» (ronda y total).
  final String Function(int round, int rounds) focusEndBody;

  /// «Fin del descanso: vuelve a concentrarte» (sin número: la ronda
  /// siguiente la dice el servidor al abrir la sala).
  final String breakEndBody;
  final String channelName;
}

/// Sala «Estudiar juntos» en la que estoy, para la barra del armazón y el aviso
/// del móvil (ADR 0045, cierre del plan premium). Una sola instancia: la
/// alimenta la pantalla de la sala ([StudyRoomBarEvent.seen]) y sigue al salir
/// de ella. La cuenta atrás es la de la fase que dio el servidor, con el reloj
/// corregido; al llegar a cero pide la sala **una vez** (no deduce la fase
/// siguiente) y vuelve a programar el aviso. El aviso de fin de fase va en su
/// propio hueco ([TimerAlertSlot.studyRoom]): llega con la app en segundo plano
/// o cerrada y no pisa el del Pomodoro. Con el canal en directo (ADR 0047), un
/// cambio de la sala (alguien empezó, entró o salió) se lee al momento.
class StudyRoomBarBloc extends Bloc<StudyRoomBarEvent, StudyRoomBarState>
    with DataChangeRefreshMixin {
  StudyRoomBarBloc({
    required this._get,
    this._scheduleAlert,
    this._cancelAlert,
    WatchDataChangesUseCaseContract? watchChanges,
    this._liveConnected,
    DateTime Function()? now,
    this.retryAfter = const Duration(seconds: 12),
  }) : _now = now ?? DateTime.now,
       super(const StudyRoomBarState()) {
    on<StudyRoomBarSeen>(_onSeen);
    on<StudyRoomBarCleared>(_onCleared);
    on<StudyRoomBarTicked>(_onTicked);
    on<StudyRoomBarLiveChanged>(_onLiveChanged);
    on<StudyRoomBarSignedOut>((_, emit) => _clear(emit));
    if (watchChanges != null) {
      watchDataChanges(
        watchChanges,
        topics: const {DataTopic.studyRoom},
        onChanged: const StudyRoomBarEvent.liveChanged(),
      );
    }
  }

  final IsTogetherLiveConnectedUseCaseContract? _liveConnected;

  final GetStudyRoomUseCaseContract _get;
  final ScheduleTimerAlertUseCaseContract? _scheduleAlert;
  final CancelTimerAlertUseCaseContract? _cancelAlert;
  final DateTime Function() _now;

  /// Tras un fallo de red al pedir la fase siguiente, cuánto se espera para
  /// volver a pedirla (la misma cadencia que la pantalla de la sala).
  final Duration retryAfter;

  Timer? _ticker;
  StudyRoomAlertTexts? _texts;
  DateTime? _scheduledFor;
  DateTime? _askAgainAt;
  bool _asking = false;

  void _onSeen(StudyRoomBarSeen event, Emitter<StudyRoomBarState> emit) {
    _texts = event.texts ?? _texts;
    _apply(event.room, event.clockOffset, emit);
  }

  /// Pinta la sala leída: si ya no estoy o terminó, la barra desaparece.
  void _apply(
    StudyRoom room,
    Duration offset,
    Emitter<StudyRoomBarState> emit,
  ) {
    if (!room.joined || room.phase.over) {
      if (state.roomId == null || state.roomId == room.id) _clear(emit);
      return;
    }
    final timed = room.phase != StudyRoomPhase.waiting;
    // Hora del móvil en la que acaba la fase: la del servidor menos el desfase.
    final endsAt = timed ? room.phaseEndsAt?.subtract(offset) : null;
    emit(
      StudyRoomBarState(
        roomId: room.id,
        phase: room.phase,
        round: room.round,
        rounds: room.rounds,
        endsAt: endsAt,
        remainingSeconds: _secondsLeft(endsAt),
      ),
    );
    // Esperando a que alguien la empiece no hay cuenta atrás: se pregunta cada
    // [retryAfter], como la pantalla, para enterarse de que ya empezó.
    // Con el canal conectado, el cambio llega solo: la pregunta es de respaldo.
    _askAgainAt = timed
        ? null
        : _now().add(
            (_liveConnected?.call() ?? false)
                ? LivePollMixin.slowPoll
                : retryAfter,
          );
    _schedule(room, endsAt);
    _ticker ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const StudyRoomBarEvent.ticked()),
    );
  }

  int? _secondsLeft(DateTime? endsAt) {
    if (endsAt == null) return null;
    final left = endsAt.difference(_now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  /// Aviso del móvil al acabar la fase en curso (concentración o descanso).
  void _schedule(StudyRoom room, DateTime? endsAt) {
    final texts = _texts;
    final schedule = _scheduleAlert;
    if (endsAt == null || texts == null || schedule == null) {
      _cancel();
      return;
    }
    if (_scheduledFor == endsAt || !endsAt.isAfter(_now())) return;
    _scheduledFor = endsAt;
    unawaited(
      schedule(
        TimerAlert(
          at: endsAt,
          title: texts.title,
          body: room.phase == StudyRoomPhase.focus
              ? texts.focusEndBody(room.round, room.rounds)
              : texts.breakEndBody,
          channelName: texts.channelName,
          slot: TimerAlertSlot.studyRoom,
        ),
      ),
    );
  }

  void _cancel() {
    _scheduledFor = null;
    final cancel = _cancelAlert;
    if (cancel != null) unawaited(cancel(slot: TimerAlertSlot.studyRoom));
  }

  /// El canal en directo avisa de un cambio en una sala: si es la mía, se lee.
  Future<void> _onLiveChanged(
    StudyRoomBarLiveChanged event,
    Emitter<StudyRoomBarState> emit,
  ) async {
    final id = state.roomId;
    if (id == null || _asking) return;
    _asking = true;
    final result = await _get(id);
    _asking = false;
    if (state.roomId != id) return;
    switch (result) {
      case Success(:final value):
        _apply(value, value.serverTime.difference(_now()), emit);
      case Failure(:final error)
          when error == const AppError.business('STUDY_ROOM_NOT_FOUND'):
        _clear(emit);
      case Failure():
        break;
    }
  }

  void _onCleared(StudyRoomBarCleared event, Emitter<StudyRoomBarState> emit) {
    if (state.roomId == null || state.roomId == event.roomId) _clear(emit);
  }

  void _clear(Emitter<StudyRoomBarState> emit) {
    _ticker?.cancel();
    _ticker = null;
    _askAgainAt = null;
    _cancel();
    emit(const StudyRoomBarState());
  }

  /// Cada segundo: la cuenta atrás y, al llegar a cero, la sala otra vez.
  Future<void> _onTicked(
    StudyRoomBarTicked event,
    Emitter<StudyRoomBarState> emit,
  ) async {
    final id = state.roomId;
    if (id == null) return;
    final left = _secondsLeft(state.endsAt);
    if (left != state.remainingSeconds) {
      emit(state.copyWith(remainingSeconds: left));
    }
    final again = _askAgainAt;
    final waiting = state.phase == StudyRoomPhase.waiting;
    if ((left != 0 && !waiting) ||
        _asking ||
        (again != null && _now().isBefore(again))) {
      return;
    }
    _asking = true;
    final result = await _get(id);
    _asking = false;
    if (state.roomId != id) return;
    switch (result) {
      case Success(:final value):
        _apply(value, value.serverTime.difference(_now()), emit);
      case Failure(:final error)
          when error == const AppError.business('STUDY_ROOM_NOT_FOUND'):
        _clear(emit);
      case Failure():
        // Sin red: se vuelve a pedir más tarde; la barra sigue a la vista.
        _askAgainAt = _now().add(retryAfter);
    }
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
