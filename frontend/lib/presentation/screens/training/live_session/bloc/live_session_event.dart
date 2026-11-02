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

  const factory LiveSessionEvent.setRecorded(SetRecord record) =
      LiveSessionSetRecorded;

  const factory LiveSessionEvent.setDeleted(String setId) =
      LiveSessionSetDeleted;

  const factory LiveSessionEvent.restStarted(int seconds) =
      LiveSessionRestStarted;

  const factory LiveSessionEvent.restAdjusted(int deltaSeconds) =
      LiveSessionRestAdjusted;

  const factory LiveSessionEvent.restSkipped() = LiveSessionRestSkipped;

  /// Acepta (o deshace) la propuesta de carga de un ejercicio: rellena sus
  /// series pendientes con la cifra propuesta.
  const factory LiveSessionEvent.loadSuggestionToggled(
    String plannedExerciseId, {
    required bool accepted,
  }) = LiveSessionLoadSuggestionToggled;

  /// «Hacerla completa»: hoy se entrena con las series planificadas en vez de
  /// las adaptadas (la decisión es de la persona; el servidor no la impide).
  const factory LiveSessionEvent.adaptationDeclined() =
      LiveSessionAdaptationDeclined;

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

  /// Se cerró la explicación del cronómetro; con [hideNextTime] no se vuelve
  /// a mostrar en este teléfono.
  const factory LiveSessionEvent.clockExplained({required bool hideNextTime}) =
      LiveSessionClockExplained;
}
