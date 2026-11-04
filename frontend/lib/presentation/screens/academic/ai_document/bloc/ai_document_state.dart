part of 'ai_document_bloc.dart';

@freezed
abstract class AiDocumentState with _$AiDocumentState {
  const factory AiDocumentState({
    @Default(StudySourceType.note) StudySourceType sourceType,
    @Default('') String sourceId,
    @Default(AiDocumentType.summary) AiDocumentType type,
    @Default(true) bool loading,
    AppError? error,
    StudyDocument? document,
    @Default(false) bool regenerating,
    AppError? actionError,
    @Default(false) bool saving,

    /// Apunte creado con «Guardar como apunte»: la página lo abre.
    String? savedNoteId,
  }) = _AiDocumentState;

  const AiDocumentState._();

  /// Solo un resumen o un mapa de una fuente con asignatura se copia a un
  /// apunte (la práctica ya vive en sus preguntas).
  bool get canSaveAsNote {
    final doc = document;
    if (doc == null || doc.subjectId == null) return false;
    return switch (doc.type) {
      AiDocumentType.practice => false,
      _ => (doc.markdown?.trim().isNotEmpty ?? false) || doc.mindMap != null,
    };
  }
}
