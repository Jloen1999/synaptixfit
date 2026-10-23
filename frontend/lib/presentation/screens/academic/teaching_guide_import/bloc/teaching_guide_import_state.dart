part of 'teaching_guide_import_bloc.dart';

/// Paso del asistente de importación.
enum GuideImportPhase {
  pick,
  uploading,
  analyzing,
  review,
  applying,
  done,
  failed,
}

@freezed
abstract class TeachingGuideImportState with _$TeachingGuideImportState {
  const TeachingGuideImportState._();

  const factory TeachingGuideImportState({
    @Default(GuideImportPhase.pick) GuideImportPhase phase,
    String? targetSubjectId,

    /// Avance de la subida del PDF (0-1).
    @Default(0) double uploadProgress,
    TeachingGuideImport? guideImport,

    /// Lo extraído por la IA, con los cambios del estudiante.
    GuideDraft? draft,

    /// Asignatura que se completa; `null` crea una nueva.
    String? destinationSubjectId,
    @Default(true) bool createDeadlines,
    TeachingGuideImportResult? result,

    /// Motivo del fallo en [GuideImportPhase.failed].
    AppError? error,

    /// Error puntual (aplicar, reintentar) que se muestra como aviso.
    AppError? actionError,

    /// Nombre del PDF elegido, para confirmar que se subió el correcto.
    String? fileName,
  }) = _TeachingGuideImportState;

  /// El fallo se arregla repitiendo: la red o la IA. Un PDF sin datos o de
  /// otro tipo pide elegir otro archivo.
  bool get canRetry =>
      guideImport != null &&
      switch (error) {
        BusinessError(:final code) =>
          code == 'AI_UNAVAILABLE' || code == 'AI_QUOTA_EXCEEDED',
        _ => true,
      };

  /// El análisis seguía en marcha cuando se cortó la red: basta con volver a
  /// consultar, sin pedir otro análisis al servidor.
  bool get waitingWasInterrupted =>
      error is! BusinessError && (guideImport?.status.isRunning ?? false);
}
