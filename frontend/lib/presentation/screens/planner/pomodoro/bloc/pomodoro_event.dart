part of 'pomodoro_bloc.dart';

@freezed
sealed class PomodoroEvent with _$PomodoroEvent {
  /// Carga la recomendación de hoy y las estadísticas. [subjectId] y
  /// [blockId] vinculan las fases que se registren (opcionales).
  const factory PomodoroEvent.started({String? subjectId, String? blockId}) =
      PomodoroStarted;

  /// Ajusta a mano la duración del bloque de concentración (antes de empezar).
  const factory PomodoroEvent.focusMinutesChanged(int minutes) =
      PomodoroFocusMinutesChanged;

  const factory PomodoroEvent.startPressed() = PomodoroStartPressed;

  const factory PomodoroEvent.pausePressed() = PomodoroPausePressed;

  const factory PomodoroEvent.resumePressed() = PomodoroResumePressed;

  /// Vuelve al inicio (concentración, ciclo 0) sin registrar nada.
  const factory PomodoroEvent.resetPressed() = PomodoroResetPressed;

  /// Termina la fase actual y pasa a la siguiente.
  const factory PomodoroEvent.skipPressed() = PomodoroSkipPressed;

  const factory PomodoroEvent.ticked() = PomodoroTicked;
}
