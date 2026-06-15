/// Fase del ciclo Pomodoro.
enum PomodoroPhase { work, shortBreak, longBreak }

/// Estado del temporizador.
enum PomodoroStatus { idle, running, paused, completed }

/// DTO inmutable que representa una sesion Pomodoro completa.
class PomodoroSession {
  /// Duracion del bloque de trabajo en segundos.
  final int workSeconds;

  /// Duracion del descanso corto en segundos.
  final int shortBreakSeconds;

  /// Duracion del descanso largo en segundos.
  final int longBreakSeconds;

  /// Cantidad de sesiones de trabajo antes de un descanso largo.
  final int sessionsBeforeLongBreak;

  /// Ciclos de trabajo completados en la sesion actual.
  final int completedCount;

  /// Fase actual del ciclo.
  final PomodoroPhase phase;

  /// Estado del temporizador.
  final PomodoroStatus status;

  /// Segundos restantes en la fase actual.
  final int secondsRemaining;

  /// Progreso normalizado de 0.0 a 1.0 (1.0 = fase completa).
  final double progress;

  const PomodoroSession({
    required this.workSeconds,
    required this.shortBreakSeconds,
    required this.longBreakSeconds,
    required this.sessionsBeforeLongBreak,
    this.completedCount = 0,
    this.phase = PomodoroPhase.work,
    this.status = PomodoroStatus.idle,
    this.secondsRemaining = 25 * 60,
    this.progress = 1.0,
  });

  PomodoroSession copyWith({
    int? workSeconds,
    int? shortBreakSeconds,
    int? longBreakSeconds,
    int? sessionsBeforeLongBreak,
    int? completedCount,
    PomodoroPhase? phase,
    PomodoroStatus? status,
    int? secondsRemaining,
    double? progress,
  }) {
    return PomodoroSession(
      workSeconds: workSeconds ?? this.workSeconds,
      shortBreakSeconds: shortBreakSeconds ?? this.shortBreakSeconds,
      longBreakSeconds: longBreakSeconds ?? this.longBreakSeconds,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      completedCount: completedCount ?? this.completedCount,
      phase: phase ?? this.phase,
      status: status ?? this.status,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      progress: progress ?? this.progress,
    );
  }

  /// Duracion total de la fase actual en segundos.
  int get currentPhaseTotalSeconds {
    switch (phase) {
      case PomodoroPhase.work:
        return workSeconds;
      case PomodoroPhase.shortBreak:
        return shortBreakSeconds;
      case PomodoroPhase.longBreak:
        return longBreakSeconds;
    }
  }
}
