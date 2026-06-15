import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pomodoro_session.dart';

/// Valores por defecto de la sesion Pomodoro.
const _defaultWorkSeconds = 25 * 60;
const _defaultShortBreakSeconds = 5 * 60;
const _defaultLongBreakSeconds = 15 * 60;
const _defaultSessionsBeforeLongBreak = 4;

/// StateNotifier que gestiona el temporizador Pomodoro con [Timer.periodic].
class PomodoroNotifier extends StateNotifier<PomodoroSession> {
  PomodoroNotifier()
      : super(
          const PomodoroSession(
            workSeconds: _defaultWorkSeconds,
            shortBreakSeconds: _defaultShortBreakSeconds,
            longBreakSeconds: _defaultLongBreakSeconds,
            sessionsBeforeLongBreak: _defaultSessionsBeforeLongBreak,
          ),
        );

  Timer? _timer;

  /// Arranca el temporizador desde idle o reinicia tras pausa.
  void iniciar() {
    _timer?.cancel();

    PomodoroSession next;
    if (state.status == PomodoroStatus.idle ||
        state.status == PomodoroStatus.completed) {
      next = state.copyWith(
        status: PomodoroStatus.running,
        phase: PomodoroPhase.work,
        secondsRemaining: state.workSeconds,
        progress: 1.0,
        completedCount: 0,
      );
    } else if (state.status == PomodoroStatus.paused) {
      next = state.copyWith(status: PomodoroStatus.running);
    } else {
      return; // ya esta corriendo
    }

    state = next;
    _startTimer();
  }

  /// Pausa el temporizador sin reiniciar.
  void pausar() {
    if (state.status != PomodoroStatus.running) return;
    _timer?.cancel();
    state = state.copyWith(status: PomodoroStatus.paused);
  }

  /// Reanuda desde pausa.
  void reanudar() {
    if (state.status != PomodoroStatus.paused) return;
    state = state.copyWith(status: PomodoroStatus.running);
    _startTimer();
  }

  /// Reinicia la sesion completa a su estado inicial (idle).
  void reiniciar() {
    _timer?.cancel();
    state = PomodoroSession(
      workSeconds: state.workSeconds,
      shortBreakSeconds: state.shortBreakSeconds,
      longBreakSeconds: state.longBreakSeconds,
      sessionsBeforeLongBreak: state.sessionsBeforeLongBreak,
    );
  }

  /// Salta el descanso actual y pasa directamente a la fase de trabajo.
  void skipBreak() {
    if (state.phase == PomodoroPhase.work) return;
    _timer?.cancel();
    state = state.copyWith(
      phase: PomodoroPhase.work,
      secondsRemaining: state.workSeconds,
      progress: 1.0,
      status: PomodoroStatus.idle,
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Callback del timer periodico cada 1s.
  void _tick() {
    if (state.status != PomodoroStatus.running) return;

    final remaining = state.secondsRemaining - 1;
    final total = state.currentPhaseTotalSeconds;
    final progress = remaining / total;

    if (remaining <= 0) {
      _transition();
    } else {
      state = state.copyWith(
        secondsRemaining: remaining,
        progress: progress,
      );
    }
  }

  /// Cambia de fase: work → break o break → work.
  void _transition() {
    _timer?.cancel();

    if (state.phase == PomodoroPhase.work) {
      // Completo un ciclo de trabajo
      final newCount = state.completedCount + 1;
      final isLongBreak = newCount % state.sessionsBeforeLongBreak == 0;
      final nextPhase =
          isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
      final nextTotal =
          isLongBreak ? state.longBreakSeconds : state.shortBreakSeconds;

      state = state.copyWith(
        completedCount: newCount,
        phase: nextPhase,
        secondsRemaining: nextTotal,
        progress: 1.0,
        status: PomodoroStatus.running,
      );
    } else {
      // Completo un descanso, vuelve a work
      state = state.copyWith(
        phase: PomodoroPhase.work,
        secondsRemaining: state.workSeconds,
        progress: 1.0,
        status: PomodoroStatus.running,
      );
    }

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider unico del temporizador Pomodoro.
final pomodoroProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroSession>(
  (ref) => PomodoroNotifier(),
);
