part of 'pomodoro_bloc.dart';

@freezed
sealed class PomodoroEvent with _$PomodoroEvent {
  /// Carga la recomendación de hoy y las estadísticas. [subjectId] y
  /// [blockId] vinculan las fases que se registren (opcionales). Con
  /// [startWithBreak] empieza por un descanso (desde «Descanso guiado»).
  ///
  /// [alertTexts]: textos del aviso del sistema al terminar cada fase (para
  /// que llegue con la app cerrada); sin ellos no se programa.
  const factory PomodoroEvent.started({
    String? subjectId,
    String? blockId,
    @Default(false) bool startWithBreak,
    PomodoroAlertTexts? alertTexts,
  }) = PomodoroStarted;

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

  /// Al entrar en la app: recupera la fase que quedó en marcha (y la registra
  /// si terminó con la app cerrada). [alertTexts] permite mostrar la
  /// notificación fija sin abrir la pantalla.
  const factory PomodoroEvent.restored({PomodoroAlertTexts? alertTexts}) =
      PomodoroRestored;

  /// Se cerró sesión: se para y se olvida la fase en curso.
  const factory PomodoroEvent.signedOut() = PomodoroSignedOut;
}
