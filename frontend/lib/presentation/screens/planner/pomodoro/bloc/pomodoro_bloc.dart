import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/planner/active_focus_timer.dart';
import '../../../../../domain/models/planner/focus.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/reminders/ongoing_timer.dart';
import '../../../../../domain/models/reminders/timer_alert.dart';
import '../../../../../domain/use_cases/reminders/cancel_timer_alert_use_case.dart';
import '../../../../../domain/use_cases/reminders/schedule_timer_alert_use_case.dart';
import '../../../../../domain/use_cases/reminders/update_ongoing_timer_use_case.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/planner/clear_active_focus_timer_use_case.dart';
import '../../../../../domain/use_cases/planner/get_focus_plan_use_case.dart';
import '../../../../../domain/use_cases/planner/get_focus_stats_use_case.dart';
import '../../../../../domain/use_cases/planner/load_active_focus_timer_use_case.dart';
import '../../../../../domain/use_cases/planner/record_focus_session_use_case.dart';
import '../../../../../domain/use_cases/planner/save_active_focus_timer_use_case.dart';

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

/// Textos (ya traducidos por la pantalla) del aviso de fin de fase y de la
/// notificación fija con la cuenta atrás.
class PomodoroAlertTexts {
  const PomodoroAlertTexts({
    required this.focusEndTitle,
    required this.focusEndBody,
    required this.breakEndTitle,
    required this.breakEndBody,
    required this.channelName,
    required this.focusRunningTitle,
    required this.breakRunningTitle,
    required this.pausedTitle,
    required this.endsAtBody,
    required this.remainingBody,
    required this.ongoingChannelName,
  });

  final String focusEndTitle;
  final String focusEndBody;
  final String breakEndTitle;
  final String breakEndBody;
  final String channelName;
  final String focusRunningTitle;
  final String breakRunningTitle;
  final String pausedTitle;

  /// «Termina a las 17:45».
  final String Function(DateTime endsAt) endsAtBody;

  /// «Quedan 12:00» (en pausa).
  final String Function(String clock) remainingBody;
  final String ongoingChannelName;
}

/// Temporizador Pomodoro de toda la app (una sola instancia): sigue contando al
/// salir de la pantalla y se ve en la barra de notificaciones del móvil. El
/// tiempo restante se calcula con el reloj ([now]) para no desviarse en
/// segundo plano; el [ticker] solo provoca el recálculo. La fase en curso se
/// guarda en el teléfono: si la app se cierra y la fase termina mientras
/// tanto, se registra al volver a abrirla. Cada fase terminada se registra en
/// la API.

class PomodoroBloc extends Bloc<PomodoroEvent, PomodoroState> {
  PomodoroBloc({
    required this._recordSession,
    required this._getStats,
    required this._getAccount,
    required this._getPlan,
    this._scheduleAlert,
    this._cancelAlert,
    this._updateOngoing,
    this._loadTimer,
    this._saveTimer,
    this._clearTimer,
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
    on<PomodoroRestored>(_onRestored);
    on<PomodoroSignedOut>(_onSignedOut);
  }

  /// Duraciones en uso: las iniciales, luego la recomendación del servidor y
  /// el ajuste manual. Cada cambio va acompañado de un estado nuevo.
  PomodoroConfig get config => _config;
  PomodoroConfig _config;
  final GetFocusPlanUseCaseContract _getPlan;
  final RecordFocusSessionUseCaseContract _recordSession;
  final GetFocusStatsUseCaseContract _getStats;
  final GetAccountUseCaseContract _getAccount;
  final ScheduleTimerAlertUseCaseContract? _scheduleAlert;
  final CancelTimerAlertUseCaseContract? _cancelAlert;
  final UpdateOngoingTimerUseCaseContract? _updateOngoing;
  final LoadActiveFocusTimerUseCaseContract? _loadTimer;
  final SaveActiveFocusTimerUseCaseContract? _saveTimer;
  final ClearActiveFocusTimerUseCaseContract? _clearTimer;

  /// La fase guardada en el teléfono ya se ha recuperado (una vez por sesión).
  bool _restored = false;

  /// Cuenta con la que se guarda la fase (se lee al recuperar).
  String? _accountId;

  /// Textos del aviso de fin de fase; null = no se programa.
  PomodoroAlertTexts? _alertTexts;

  final DateTime Function() _now;
  final Stream<void> Function() _ticker;

  StreamSubscription<void>? _tick;

  /// Instante en que termina la fase en curso (solo mientras corre).
  DateTime? _endsAt;

  Future<void> _onStarted(
    PomodoroStarted event,
    Emitter<PomodoroState> emit,
  ) async {
    _alertTexts = event.alertTexts ?? _alertTexts;
    await _restore(emit);
    // Con una fase en marcha (se abrió de nuevo la pantalla) no se cambia nada.
    if (state.status != PomodoroStatus.idle) {
      _syncOngoing();
      await _loadStats(emit);
      return;
    }
    // Sin fase en marcha, cada apertura decide a qué se vincula (también a
    // nada): la instancia es única y no debe arrastrar la de antes.
    if (state.subjectId != event.subjectId || state.blockId != event.blockId) {
      emit(state.copyWith(subjectId: event.subjectId, blockId: event.blockId));
    }
    // La pausa se muestra desde el principio (sin pasar por «Concentración»);
    // al llegar el plan se ajusta su duración a la recomendada de hoy.
    if (event.startWithBreak) {
      final total = config.minutesOf(FocusPhase.shortBreak) * 60;
      emit(
        state.copyWith(
          phase: FocusPhase.shortBreak,
          totalSeconds: total,
          remainingSeconds: total,
        ),
      );
    }
    await Future.wait([_loadPlan(emit), _loadStats(emit)]);
  }

  /// Si falla, se queda con las duraciones por defecto (sin aviso: no impide
  /// concentrarse).
  Future<void> _loadPlan(Emitter<PomodoroState> emit) async {
    final plan = (await _getPlan()).valueOrNull;
    if (plan == null) return;
    _config = PomodoroConfig.fromPlan(plan);
    final untouched =
        state.status == PomodoroStatus.idle &&
        state.remainingSeconds == state.totalSeconds &&
        state.completedFocusCycles == 0;
    if (untouched) {
      final total = _config.minutesOf(state.phase) * 60;
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

  /// Aviso del sistema al terminar la fase en curso: llega aunque la app esté
  /// cerrada o en segundo plano.
  void _scheduleEndAlert() {
    final texts = _alertTexts;
    final endsAt = _endsAt;
    final schedule = _scheduleAlert;
    if (texts == null || endsAt == null || schedule == null) return;
    final focus = state.phase == FocusPhase.focus;
    unawaited(
      schedule(
        TimerAlert(
          at: endsAt,
          title: focus ? texts.focusEndTitle : texts.breakEndTitle,
          body: focus ? texts.focusEndBody : texts.breakEndBody,
          channelName: texts.channelName,
        ),
      ),
    );
  }

  void _cancelEndAlert() {
    final cancel = _cancelAlert;
    if (cancel != null) unawaited(cancel());
  }

  /// Guarda la fase en curso en el teléfono (o la olvida si no hay) y pone la
  /// notificación fija al día.
  void _persist() {
    if (state.status == PomodoroStatus.idle) {
      final clear = _clearTimer;
      if (clear != null) unawaited(clear());
    } else {
      final save = _saveTimer;
      if (save != null) {
        unawaited(
          save(
            ActiveFocusTimer(
              phase: state.phase,
              running: state.status == PomodoroStatus.running,
              endsAt: _endsAt,
              totalSeconds: state.totalSeconds,
              remainingSeconds: state.remainingSeconds,
              completedFocusCycles: state.completedFocusCycles,
              subjectId: state.subjectId,
              blockId: state.blockId,
              accountId: _accountId,
            ),
          ),
        );
      }
    }
    _syncOngoing();
  }

  /// Notificación fija: cuenta atrás mientras corre, «en pausa» con lo que
  /// queda, y nada si no hay fase en curso.
  void _syncOngoing() {
    final update = _updateOngoing;
    final texts = _alertTexts;
    if (update == null) return;
    if (state.status == PomodoroStatus.idle || texts == null) {
      if (state.status == PomodoroStatus.idle) unawaited(update(null));
      return;
    }
    final endsAt = _endsAt;
    final running = state.status == PomodoroStatus.running && endsAt != null;
    unawaited(
      update(
        OngoingTimer(
          title: !running
              ? texts.pausedTitle
              : state.phase == FocusPhase.focus
              ? texts.focusRunningTitle
              : texts.breakRunningTitle,
          body: running
              ? texts.endsAtBody(endsAt)
              : texts.remainingBody(clockText(state.remainingSeconds)),
          endsAt: running ? endsAt : null,
          channelName: texts.ongoingChannelName,
        ),
      ),
    );
  }

  /// «mm:ss».
  static String clockText(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';

  /// Recupera la fase guardada en el teléfono. Si terminó con la app cerrada,
  /// se registra ya como completada (antes se perdía).
  Future<void> _restore(Emitter<PomodoroState> emit) async {
    if (_restored) return;
    _restored = true;
    final load = _loadTimer;
    if (load == null || state.status != PomodoroStatus.idle) return;
    _accountId = (await _getAccount()).valueOrNull?.id;
    final saved = (await load()).valueOrNull;
    // Sin fase guardada no debe quedar una notificación fija de otra vez.
    if (saved == null) {
      final update = _updateOngoing;
      if (update != null) unawaited(update(null));
      return;
    }
    // Fase de otra cuenta en este teléfono: se descarta sin registrarla.
    if (saved.accountId != null && saved.accountId != _accountId) {
      final clear = _clearTimer;
      if (clear != null) unawaited(clear());
      final update = _updateOngoing;
      if (update != null) unawaited(update(null));
      return;
    }
    final remaining = saved.remainingAt(_now());
    emit(
      state.copyWith(
        phase: saved.phase,
        status: saved.running ? PomodoroStatus.running : PomodoroStatus.paused,
        totalSeconds: saved.totalSeconds,
        remainingSeconds: remaining,
        completedFocusCycles: saved.completedFocusCycles,
        subjectId: saved.subjectId,
        blockId: saved.blockId,
      ),
    );
    if (saved.running && remaining == 0) {
      await _finishPhase(emit, completed: true);
      return;
    }
    if (saved.running) {
      _endsAt = saved.endsAt;
      _startTicker();
      // En un proceso nuevo la alarma anterior pudo perderse: se vuelve a poner.
      _scheduleEndAlert();
    }
    _syncOngoing();
  }

  Future<void> _onRestored(
    PomodoroRestored event,
    Emitter<PomodoroState> emit,
  ) async {
    _alertTexts = event.alertTexts ?? _alertTexts;
    await _restore(emit);
  }

  /// Al cerrar sesión no debe quedar nada de la cuenta anterior.
  void _onSignedOut(PomodoroSignedOut event, Emitter<PomodoroState> emit) {
    _stopTicker();
    _cancelEndAlert();
    _endsAt = null;
    _restored = false;
    _accountId = null;
    _config = const PomodoroConfig();
    final total = config.focusMinutes * 60;
    emit(PomodoroState(totalSeconds: total, remainingSeconds: total));
    _persist();
  }

  void _onStart(PomodoroStartPressed event, Emitter<PomodoroState> emit) {
    if (state.status != PomodoroStatus.idle) return;
    _endsAt = _now().add(Duration(seconds: state.remainingSeconds));
    emit(state.copyWith(status: PomodoroStatus.running));
    _startTicker();
    _scheduleEndAlert();
    _persist();
  }

  void _onPause(PomodoroPausePressed event, Emitter<PomodoroState> emit) {
    if (state.status != PomodoroStatus.running) return;
    _stopTicker();
    _cancelEndAlert();
    final remaining = _remaining();
    _endsAt = null;
    emit(
      state.copyWith(
        status: PomodoroStatus.paused,
        remainingSeconds: remaining,
      ),
    );
    _persist();
  }

  void _onResume(PomodoroResumePressed event, Emitter<PomodoroState> emit) {
    if (state.status != PomodoroStatus.paused) return;
    _endsAt = _now().add(Duration(seconds: state.remainingSeconds));
    emit(state.copyWith(status: PomodoroStatus.running));
    _startTicker();
    _scheduleEndAlert();
    _persist();
  }

  void _onReset(PomodoroResetPressed event, Emitter<PomodoroState> emit) {
    _stopTicker();
    _cancelEndAlert();
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
    _persist();
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
    bool notify = true,
  }) async {
    _stopTicker();
    // Con la app abierta ya se avisa en pantalla; al saltar o salir, no debe
    // llegar el aviso de una fase que ya no corre.
    _cancelEndAlert();
    final remaining = completed ? 0 : _remaining();
    _endsAt = null;
    final finished = state.phase;
    final phaseSeconds = state.totalSeconds;
    final elapsedMinutes = ((phaseSeconds - remaining) / 60).round();
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
        notice: notify
            ? PomodoroNotice.phaseFinished(
                finished: finished,
                next: next,
                completed: completed,
              )
            : state.notice,
        noticeId: notify ? state.noticeId + 1 : state.noticeId,
      ),
    );
    _persist();

    // Fases saltadas sin apenas tiempo no se registran (la API pide ≥ 1 min).
    // Completada, cuenta la duración que tenía la fase (pudo ajustarse).
    final minutes = completed ? (phaseSeconds / 60).round() : elapsedMinutes;
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
    // Al salir de la pantalla solo importa guardar: no hay nadie a quien avisar.
    if (!notify) return;
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
