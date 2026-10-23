part of 'live_session_bloc.dart';

@freezed
sealed class LiveSessionEvent with _$LiveSessionEvent {
  const factory LiveSessionEvent.started(String sessionId) = LiveSessionStarted;

  /// Un segundo más (lo envía la página con un temporizador).
  const factory LiveSessionEvent.ticked() = LiveSessionTicked;

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

  /// Finaliza con el esfuerzo percibido (RPE 1-10).
  const factory LiveSessionEvent.finishRequested(int rpe) =
      LiveSessionFinishRequested;

  const factory LiveSessionEvent.abandonRequested() =
      LiveSessionAbandonRequested;
}
