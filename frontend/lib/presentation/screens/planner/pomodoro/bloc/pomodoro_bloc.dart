import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/planner/focus.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/planner/get_focus_plan_use_case.dart';
import '../../../../../domain/use_cases/planner/get_focus_stats_use_case.dart';
import '../../../../../domain/use_cases/planner/record_focus_session_use_case.dart';

part 'pomodoro_bloc.freezed.dart';
part 'pomodoro_event.dart';
part 'pomodoro_state.dart';

/// Duraciones del temporizador Pomodoro. Por defecto, el ciclo de atención de
/// 52/17 min; al llegar la recomendación del servidor ([FocusPlan]) se usa esa.
class PomodoroConfig {
  const PomodoroConfig({
    this.focusMinutes = 52,
    this.shortBreakMinutes = 17,
    this.longBreakMinutes = 30,
    this.cyclesBeforeLongBreak = 3,
    this.minFocusMinutes = 15,
    this.maxFocusMinutes = 90,
  });

  factory PomodoroConfig.fromPlan(FocusPlan plan) => PomodoroConfig(
    focusMinutes: plan.focusMinutes,
    shortBreakMinutes: plan.shortBreakMinutes,
    longBreakMinutes: plan.longBreakMinutes,
    cyclesBeforeLongBreak: plan.cyclesBeforeLongBreak,
    minFocusMinutes: plan.minFocusMinutes,
    maxFocusMinutes: plan.maxFocusMinutes,
  );

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int cyclesBeforeLongBreak;
  final int minFocusMinutes;
  final int maxFocusMinutes;

  PomodoroConfig withFocusMinutes(int minutes) => PomodoroConfig(
    focusMinutes: minutes.clamp(minFocusMinutes, maxFocusMinutes),
    shortBreakMinutes: shortBreakMinutes,
    longBreakMinutes: longBreakMinutes,
    cyclesBeforeLongBreak: cyclesBeforeLongBreak,
    minFocusMinutes: minFocusMinutes,
    maxFocusMinutes: maxFocusMinutes,
  );

  int minutesOf(FocusPhase phase) => switch (phase) {
    FocusPhase.focus => focusMinutes,
    FocusPhase.shortBreak => shortBreakMinutes,
    FocusPhase.longBreak => longBreakMinutes,
  };
}

/// Temporizador Pomodoro en el cliente. El tiempo restante se calcula con el
/// reloj ([now]) para no desviarse si la app se queda en segundo plano; el
/// [ticker] solo provoca el recálculo. Cada fase terminada se registra en la API.
class PomodoroBloc extends Bloc<PomodoroEvent, PomodoroState> {
  PomodoroBloc({
    required this._recordSession,
    required this._getStats,
    required this._getAccount,
    required this._getPlan,
    PomodoroConfig config = const PomodoroConfig(),
    DateTime Function()? now,
    Stream<void> Function()? ticker,
  }) : _config = config,
       _now = now ?? DateTime.now,
       _ticker =
           ticker ?? (() => Stream<void>.periodic(const Duration(seconds: 1))),
       super(
         PomodoroState(
           totalSeconds: config.focusMinutes * 60,
           remainingSeconds: config.focusMinutes * 60,
         ),
       ) {
    on<PomodoroStarted>(_onStarted);
    on<PomodoroFocusMinutesChanged>(_onFocusMinutesChanged);
    on<PomodoroStartPressed>(_onStart);
    on<PomodoroPausePressed>(_onPause);
    on<PomodoroResumePressed>(_onResume);
    on<PomodoroResetPressed>(_onReset);
    on<PomodoroSkipPressed>(_onSkip);
    on<PomodoroTicked>(_onTick);
  }

  /// Duraciones en uso: las iniciales, luego la recomendación del servidor y
  /// el ajuste manual. Cada cambio va acompañado de un estado nuevo.
  PomodoroConfig get config => _config;
  PomodoroConfig _config;
  final GetFocusPlanUseCaseContract _getPlan;
  final RecordFocusSessionUseCaseContract _recordSession;
  final GetFocusStatsUseCaseContract _getStats;
  final GetAccountUseCaseContract _getAccount;

  final DateTime Function() _now;
  final Stream<void> Function() _ticker;

  StreamSubscription<void>? _tick;

  /// Instante en que termina la fase en curso (solo mientras corre).
  DateTime? _endsAt;

  Future<void> _onStarted(
    PomodoroStarted event,
    Emitter<PomodoroState> emit,
  ) async {
    if (event.subjectId != null || event.blockId != null) {
      emit(state.copyWith(subjectId: event.subjectId, blockId: event.blockId));
    }
    await Future.wait([_loadPlan(emit), _loadStats(emit)]);
  }

  /// Si falla, se queda con las duraciones por defecto (sin aviso: no impide
  /// concentrarse).
  Future<void> _loadPlan(Emitter<PomodoroState> emit) async {
    final plan = (await _getPlan()).valueOrNull;
    if (plan == null) return;
    _config = PomodoroConfig.fromPlan(plan);
    if (state.canAdjust) {
      final total = _config.focusMinutes * 60;
      emit(
        state.copyWith(
          plan: plan,
          totalSeconds: total,
          remainingSeconds: total,
        ),
      );
    } else {
      emit(state.copyWith(plan: plan));
    }
  }

  void _onFocusMinutesChanged(
    PomodoroFocusMinutesChanged event,
    Emitter<PomodoroState> emit,
  ) {
    if (!state.canAdjust) return;
    _config = _config.withFocusMinutes(event.minutes);
    final total = _config.focusMinutes * 60;
    emit(state.copyWith(totalSeconds: total, remainingSeconds: total));
  }

  Future<void> _loadStats(Emitter<PomodoroState> emit) async {
    emit(state.copyWith(statsLoading: true));
    final result = await _getStats();
    emit(
      state.copyWith(
        statsLoading: false,
        stats: result.valueOrNull ?? state.stats,
        statsError: result.errorOrNull,
      ),
    );
  }

  void _startTicker() {
    unawaited(_tick?.cancel());
    _tick = _ticker().listen((_) {
      if (!isClosed) add(const PomodoroEvent.ticked());
    });
  }

  void _stopTicker() {
    unawaited(_tick?.cancel());
    _tick = null;
  }

  void _onStart(PomodoroStartPressed event, Emitter<PomodoroState> emit) {
    if (state.status != PomodoroStatus.idle) return;
    _endsAt = _now().add(Duration(seconds: state.remainingSeconds));
    emit(state.copyWith(status: PomodoroStatus.running));
    _startTicker();
  }

  void _onPause(PomodoroPausePressed event, Emitter<PomodoroState> emit) {
    if (state.status != PomodoroStatus.running) return;
    _stopTicker();
    final remaining = _remaining();
    _endsAt = null;
    emit(
      state.copyWith(
        status: PomodoroStatus.paused,
        remainingSeconds: remaining,
      ),
    );
  }

  void _onResume(PomodoroResumePressed event, Emitter<PomodoroState> emit) {
    if (state.status != PomodoroStatus.paused) return;
    _endsAt = _now().add(Duration(seconds: state.remainingSeconds));
    emit(state.copyWith(status: PomodoroStatus.running));
    _startTicker();
  }

  void _onReset(PomodoroResetPressed event, Emitter<PomodoroState> emit) {
    _stopTicker();
    _endsAt = null;
    final total = config.focusMinutes * 60;
    emit(
      state.copyWith(
        phase: FocusPhase.focus,
        status: PomodoroStatus.idle,
        totalSeconds: total,
        remainingSeconds: total,
        completedFocusCycles: 0,
      ),
    );
  }

  int _remaining() {
    final endsAt = _endsAt;
    if (endsAt == null) return state.remainingSeconds;
    final ms = endsAt.difference(_now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  Future<void> _onTick(
    PomodoroTicked event,
    Emitter<PomodoroState> emit,
  ) async {
    if (state.status != PomodoroStatus.running) return;
    final remaining = _remaining();
    if (remaining > 0) {
      if (remaining != state.remainingSeconds) {
        emit(state.copyWith(remainingSeconds: remaining));
      }
      return;
    }
    await _finishPhase(emit, completed: true);
  }

  Future<void> _onSkip(
    PomodoroSkipPressed event,
    Emitter<PomodoroState> emit,
  ) => _finishPhase(emit, completed: false);

  /// Cierra la fase actual, la registra (si procede) y prepara la siguiente.
  Future<void> _finishPhase(
    Emitter<PomodoroState> emit, {
    required bool completed,
  }) async {
    _stopTicker();
    final remaining = completed ? 0 : _remaining();
    _endsAt = null;
    final finished = state.phase;
    final elapsedMinutes = ((state.totalSeconds - remaining) / 60).round();
    final cycles = finished == FocusPhase.focus && completed
        ? state.completedFocusCycles + 1
        : state.completedFocusCycles;
    final next = switch (finished) {
      FocusPhase.focus
          when cycles > 0 &&
              completed &&
              cycles % config.cyclesBeforeLongBreak == 0 =>
        FocusPhase.longBreak,
      FocusPhase.focus => FocusPhase.shortBreak,
      _ => FocusPhase.focus,
    };
    final total = config.minutesOf(next) * 60;
    emit(
      state.copyWith(
        phase: next,
        status: PomodoroStatus.idle,
        totalSeconds: total,
        remainingSeconds: total,
        completedFocusCycles: cycles,
        notice: PomodoroNotice.phaseFinished(finished: finished, next: next),
        noticeId: state.noticeId + 1,
      ),
    );

    // Fases saltadas sin apenas tiempo no se registran (la API pide ≥ 1 min).
    final minutes = completed ? config.minutesOf(finished) : elapsedMinutes;
    if (minutes < 1) return;
    final result = await _recordSession(
      FocusSessionRecord(
        phase: finished,
        durationMinutes: minutes.clamp(1, 180),
        completed: completed,
        subjectId: state.subjectId,
        blockId: state.blockId,
      ),
    );
    switch (result) {
      case Failure(:final error):
        emit(
          state.copyWith(
            notice: PomodoroNotice.recordFailed(error),
            noticeId: state.noticeId + 1,
          ),
        );
        return;
      case Success(:final value):
        await _loadStats(emit);
        await _notifyXp(emit, value);
    }
  }

  /// Avisa según el estado de XP que decidió el servidor: la XP ganada (y
  /// refresca la cuenta para el nivel), el tope diario o nada.
  Future<void> _notifyXp(
    Emitter<PomodoroState> emit,
    FocusSessionResult result,
  ) async {
    switch (result.xpStatus) {
      case FocusXpStatus.awarded:
        final account = (await _getAccount()).valueOrNull;
        emit(
          state.copyWith(
            notice: PomodoroNotice.xpEarned(
              xp: result.xpAwarded,
              account: account,
            ),
            noticeId: state.noticeId + 1,
          ),
        );
      case FocusXpStatus.dailyCapReached:
        emit(
          state.copyWith(
            notice: const PomodoroNotice.dailyXpLimitReached(),
            noticeId: state.noticeId + 1,
          ),
        );
      case FocusXpStatus.notEligible:
        return;
    }
  }

  @override
  Future<void> close() {
    _stopTicker();
    return super.close();
  }
}
