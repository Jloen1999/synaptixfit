part of 'teaching_guide_import_bloc.dart';

@freezed
sealed class TeachingGuideImportEvent with _$TeachingGuideImportEvent {
  /// [targetSubjectId]: asignatura desde la que se abrió (se completa esa).
  const factory TeachingGuideImportEvent.started({String? targetSubjectId}) =
      TeachingGuideImportStarted;

  const factory TeachingGuideImportEvent.filePicked(FileUploadPayload payload) =
      TeachingGuideImportFilePicked;

  /// Vuelve a analizar el mismo PDF tras un fallo de la IA.
  const factory TeachingGuideImportEvent.retried() = TeachingGuideImportRetried;

  /// Descarta lo subido y vuelve a elegir archivo.
  const factory TeachingGuideImportEvent.restarted() =
      TeachingGuideImportRestarted;

  const factory TeachingGuideImportEvent.draftChanged(GuideDraft draft) =
      TeachingGuideImportDraftChanged;

  /// `null` crea una asignatura nueva.
  const factory TeachingGuideImportEvent.destinationChanged(String? subjectId) =
      TeachingGuideImportDestinationChanged;

  const factory TeachingGuideImportEvent.createDeadlinesChanged(bool value) =
      TeachingGuideImportCreateDeadlinesChanged;

  const factory TeachingGuideImportEvent.applied() = TeachingGuideImportApplied;
}
