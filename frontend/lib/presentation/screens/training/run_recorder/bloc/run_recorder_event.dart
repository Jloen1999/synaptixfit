part of 'run_recorder_bloc.dart';

@freezed
sealed class RunRecorderEvent with _$RunRecorderEvent {
  /// Con [workoutId] guía ese entreno; con [eventId] lo deja hecho en el
  /// calendario al guardarse. Si hay una carrera sin terminar, la recupera.
  const factory RunRecorderEvent.started({
    String? workoutId,
    String? eventId,
    required RunNotificationTexts texts,
  }) = RunRecorderStarted;

  const factory RunRecorderEvent.kindChanged(ActivityKind kind) =
      RunRecorderKindChanged;

  /// «Empezar»: la pantalla ya comprobó el permiso de ubicación.
  const factory RunRecorderEvent.recordingStarted() =
      RunRecorderRecordingStarted;

  const factory RunRecorderEvent.fixReceived(RunFix fix) =
      RunRecorderFixReceived;

  const factory RunRecorderEvent.ticked() = RunRecorderTicked;

  const factory RunRecorderEvent.pauseRequested() = RunRecorderPauseRequested;

  const factory RunRecorderEvent.resumeRequested() = RunRecorderResumeRequested;

  /// «Terminar» con «¿Cuánto te ha costado?» (1-10).
  const factory RunRecorderEvent.finishRequested(int effort) =
      RunRecorderFinishRequested;

  const factory RunRecorderEvent.discardRequested() =
      RunRecorderDiscardRequested;

  /// La app pasa a segundo plano: se guarda ya en el teléfono.
  const factory RunRecorderEvent.persistRequested() =
      RunRecorderPersistRequested;

  const factory RunRecorderEvent.gpsFailed(AppError error) =
      RunRecorderGpsFailed;

  /// «Abrir los ajustes de la app» de la ayuda de batería (para quitar el
  /// ahorro de batería que corta el GPS).
  const factory RunRecorderEvent.batterySettingsOpened() =
      RunRecorderBatterySettingsOpened;
}
