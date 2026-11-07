part of 'run_recorder_bloc.dart';

enum RunPhase {
  loading,

  /// Web o escritorio: se graba desde el móvil.
  unsupported,

  /// Listo para «Empezar».
  ready,
  recording,
  paused,
  saving,

  /// Guardada en el servidor.
  saved,

  /// Sin conexión: en la cola del teléfono, se subirá sola.
  queued,

  /// El servidor la rechazó por una regla (muy corta, muy antigua).
  rejected,
  discarded,
}

@freezed
abstract class RunRecorderState with _$RunRecorderState {
  const factory RunRecorderState({
    @Default(RunPhase.loading) RunPhase phase,
    @Default(ActivityKind.run) ActivityKind kind,
    RunRecording? recording,
    RunWorkout? workout,
    String? eventId,
    RunGuide? guide,

    /// Cuántas veces se ha cambiado de paso (para anunciarlo).
    @Default(0) int stepChanges,

    /// Cifras en directo (orientativas).
    @Default(0) double meters,
    @Default(0) int activeSeconds,
    DateTime? lastFixAt,

    /// La precisión del último punto es mala (no cuenta).
    @Default(false) bool weakSignal,

    /// Hace rato que no llega ningún punto: se busca señal.
    @Default(false) bool signalLost,

    /// Pulso para avisar de que el GPS del móvil está apagado.
    @Default(false) bool locationOff,
    AppError? gpsError,
    RunSaved? saved,
    AppError? finishError,
  }) = _RunRecorderState;

  const RunRecorderState._();

  int? get paceSecondsPerKm =>
      RunLiveStats.paceSecondsPerKm(meters, activeSeconds);

  /// Con menos de [SportActivity.minMinutes] minutos no contaría.
  bool get tooShort =>
      activeSeconds < SportActivity.minMinutes * Duration.secondsPerMinute;
}
