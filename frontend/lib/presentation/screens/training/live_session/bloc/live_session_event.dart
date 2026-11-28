part of 'live_session_bloc.dart';

@freezed
sealed class LiveSessionEvent with _$LiveSessionEvent {
  /// Reintenta subir las series apuntadas sin conexión.
  const factory LiveSessionEvent.pendingRetried() = LiveSessionPendingRetried;

  const factory LiveSessionEvent.started(String sessionId) = LiveSessionStarted;

  /// Recalcula cronómetro y descanso con el reloj (lo envía la página cada
  /// segundo con un temporizador).
  const factory LiveSessionEvent.ticked() = LiveSessionTicked;

  /// La app vuelve a primer plano: se recalcula ya con el reloj (el
  /// temporizador pudo quedar parado) y se reintenta subir lo pendiente.
  const factory LiveSessionEvent.resumed() = LiveSessionResumed;

  /// Ejercicio en el que se está trabajando (cuenta su duración real).
  const factory LiveSessionEvent.exerciseSelected(String? plannedExerciseId) =
      LiveSessionExerciseSelected;

  /// «Ir al siguiente»: acabado el ejercicio que se miraba, pasa a
  /// [plannedExerciseId] y la pantalla lo resalta y lo anuncia (ADR 0062).
  const factory LiveSessionEvent.nextExerciseRequested(
    String plannedExerciseId,
  ) = LiveSessionNextExerciseRequested;

  /// Apunta (o corrige) una serie. Con [startRest] falso no arranca su
  /// descanso: al corregirla o al deshacer un «Desmarcar».
  const factory LiveSessionEvent.setRecorded(
    SetRecord record, {
    @Default(true) bool startRest,
  }) = LiveSessionSetRecorded;

  /// Desmarca una serie (la quita de la sesión; se puede deshacer).
  const factory LiveSessionEvent.setDeleted(String setId) =
      LiveSessionSetDeleted;

  const factory LiveSessionEvent.restStarted(int seconds) =
      LiveSessionRestStarted;

  const factory LiveSessionEvent.restAdjusted(int deltaSeconds) =
      LiveSessionRestAdjusted;

  const factory LiveSessionEvent.restSkipped() = LiveSessionRestSkipped;

  /// «Hacerla completa»: hoy se entrena con las series planificadas en vez de
  /// las adaptadas (la decisión es de la persona; el servidor no la impide).
  const factory LiveSessionEvent.adaptationDeclined() =
      LiveSessionAdaptationDeclined;

  /// «Deshacer» de «Hacerla completa»: vuelve a las series adaptadas de hoy.
  const factory LiveSessionEvent.adaptationRestored(
    SessionAdaptation adaptation,
  ) = LiveSessionAdaptationRestored;

  /// Finaliza con el esfuerzo percibido (RPE 1-10).
  const factory LiveSessionEvent.finishRequested(int rpe) =
      LiveSessionFinishRequested;

  const factory LiveSessionEvent.abandonRequested() =
      LiveSessionAbandonRequested;

  /// Empieza el cronómetro de la serie [setNumber] de [plannedExerciseId]
  /// (opcional: una serie se puede marcar sin usarlo). Corta el descanso.
  const factory LiveSessionEvent.setTimerStarted(
    String? plannedExerciseId,
    int setNumber,
  ) = LiveSessionSetTimerStarted;

  /// Pausa la sesión (y el cronómetro de la serie): el tiempo en pausa no
  /// cuenta para la carga ni las kcal (ADR 0030).
  const factory LiveSessionEvent.pauseRequested() = LiveSessionPauseRequested;

  /// Reanuda la sesión (y el cronómetro de la serie, si había uno).
  const factory LiveSessionEvent.resumeRequested() = LiveSessionResumeRequested;

  /// Entreno juntos (ADR 0047): la pausa del grupo cambió en el servidor (otra
  /// persona pausó o reanudó, y el servidor ya hizo lo mismo con esta sesión).
  /// Se lee la sesión y se adopta su pausa sin volver a mandarla.
  /// [pausedBy] es el nombre de quien la puso si no fui yo (nulo si fui yo o si
  /// no hay pausa).
  const factory LiveSessionEvent.groupPauseChanged({String? pausedBy}) =
      LiveSessionGroupPauseChanged;

  /// «Usar hoy»: hace [swap] en lugar del ejercicio del hueco solo en esta
  /// sesión; nulo, vuelve al de la rutina.
  /// Respuesta a «¿Cuántas más podrías haber hecho?» tras la serie
  /// [setNumber] de un ejercicio que se calibra (ADR 0054).
  const factory LiveSessionEvent.calibrationAnswered({
    required String plannedExerciseId,
    required int setNumber,
    required CalibrationAnswer answer,
  }) = LiveSessionCalibrationAnswered;

  /// «Añadir ejercicio» a la sesión libre (ADR 0067).
  const factory LiveSessionEvent.exerciseAdded(String exerciseId) =
      LiveSessionExerciseAdded;

  const factory LiveSessionEvent.exerciseSwapped(
    String plannedExerciseId,
    ExerciseSwap? swap,
  ) = LiveSessionExerciseSwapped;
}
