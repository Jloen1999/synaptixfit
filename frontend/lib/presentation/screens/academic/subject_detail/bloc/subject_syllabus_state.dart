part of 'subject_syllabus_bloc.dart';

/// Avisos de una acción terminada (se muestran en un SnackBar).
enum SyllabusMessage { fileUploaded, fileDeleted, noteDeleted }

@freezed
abstract class SubjectSyllabusState with _$SubjectSyllabusState {
  const factory SubjectSyllabusState({
    @Default('') String subjectId,
    @Default(true) bool loading,
    AppError? error,
    @Default(<Note>[]) List<Note> notes,
    @Default(<SubjectFile>[]) List<SubjectFile> files,

    /// Documentos de IA guardados por id de apunte o archivo.
    @Default(<String, DocumentAvailability>{})
    Map<String, DocumentAvailability> availability,

    /// Avance de la subida en curso (null si no hay ninguna).
    double? uploadProgress,
    @Default(false) bool busy,
    AppError? actionError,
    SyllabusMessage? message,

    /// Material listo para abrir su repaso o su práctica.
    ({String materialId, bool practice})? navigation,
  }) = _SubjectSyllabusState;

  const SubjectSyllabusState._();

  bool get uploading => uploadProgress != null;
}
