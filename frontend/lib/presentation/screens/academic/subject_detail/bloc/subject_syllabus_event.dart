part of 'subject_syllabus_bloc.dart';

@freezed
sealed class SubjectSyllabusEvent with _$SubjectSyllabusEvent {
  const factory SubjectSyllabusEvent.started(String subjectId) =
      SubjectSyllabusStarted;

  const factory SubjectSyllabusEvent.refreshed() = SubjectSyllabusRefreshed;

  const factory SubjectSyllabusEvent.uploadRequested(
    FileUploadPayload payload,
  ) = SubjectSyllabusUploadRequested;

  const factory SubjectSyllabusEvent.fileDeleted(String fileId) =
      SubjectSyllabusFileDeleted;

  const factory SubjectSyllabusEvent.noteDeleted(String noteId) =
      SubjectSyllabusNoteDeleted;

  /// Registra la fuente como material y abre el repaso o la práctica.
  const factory SubjectSyllabusEvent.materialRequested({
    required StudySourceType sourceType,
    required String sourceId,
    required bool practice,
  }) = SubjectSyllabusMaterialRequested;
}
