import '../enums/ai_document_type.dart';
import '../enums/artifact_kind.dart';
import '../enums/study_source_type.dart';
import '../models/academic/mind_map.dart';
import '../models/academic/note.dart';
import '../models/academic/study_artifact.dart';
import '../models/academic/study_document.dart';
import '../models/result/app_result.dart';

/// Asistente de estudio con IA: documentos por fuente y generación multi-fuente.
abstract interface class StudyAssistantRepositoryContract {
  Future<AppResult<StudyDocument>> getDocument(
    StudySourceType sourceType,
    String sourceId,
    AiDocumentType type,
  );

  /// Genera (o regenera, sobrescribiendo) el documento.
  Future<AppResult<StudyDocument>> generateDocument(
    StudySourceType sourceType,
    String sourceId,
    AiDocumentType type,
  );

  Future<AppResult<DocumentAvailability>> getAvailability(
    StudySourceType sourceType,
    String sourceId,
  );

  Future<AppResult<StudyArtifact>> generateArtifact(
    ArtifactKind kind,
    List<StudySourceRef> sources,
  );

  Future<AppResult<Note>> saveArtifactAsNote({
    String? subjectId,
    String? title,
    String? markdown,
    MindMap? mindMap,
  });

  Future<AppResult<SavedQuiz>> saveArtifactAsQuiz({
    required String subjectId,
    String? title,
    required List<QuestionDraft> questions,
  });
}
