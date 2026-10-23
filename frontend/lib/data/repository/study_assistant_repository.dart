import '../../domain/enums/ai_document_type.dart';
import '../../domain/enums/artifact_kind.dart';
import '../../domain/enums/study_source_type.dart';
import '../../domain/models/academic/mind_map.dart';
import '../../domain/models/academic/note.dart';
import '../../domain/models/academic/study_artifact.dart';
import '../../domain/models/academic/study_document.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/study_assistant_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/academic/dto/study_dtos.dart';
import '../remote_data_source/academic/study_remote_data_source.dart';

class StudyAssistantRepository implements StudyAssistantRepositoryContract {
  StudyAssistantRepository(this._remote);

  final StudyRemoteDataSource _remote;

  @override
  Future<AppResult<StudyDocument>> getDocument(
    StudySourceType sourceType,
    String sourceId,
    AiDocumentType type,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.getDocument(
      sourceType.apiValue,
      sourceId,
      type.apiValue,
    )).toDomain(),
  );

  @override
  Future<AppResult<StudyDocument>> generateDocument(
    StudySourceType sourceType,
    String sourceId,
    AiDocumentType type,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.generateDocument(
      sourceType.apiValue,
      sourceId,
      type.apiValue,
    )).toDomain(),
  );

  @override
  Future<AppResult<DocumentAvailability>> getAvailability(
    StudySourceType sourceType,
    String sourceId,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.getAvailability(
      sourceType.apiValue,
      sourceId,
    )).toDomain(),
  );

  @override
  Future<AppResult<StudyArtifact>> generateArtifact(
    ArtifactKind kind,
    List<StudySourceRef> sources,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.generateArtifact({
      'kind': kind.apiValue,
      'sources': [
        for (final s in sources) {'type': s.type.apiValue, 'id': s.id},
      ],
    })).toDomain(),
  );

  @override
  Future<AppResult<Note>> saveArtifactAsNote({
    String? subjectId,
    String? title,
    String? markdown,
    MindMap? mindMap,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.saveAsNote({
      'subjectId': ?subjectId,
      'title': ?title,
      'markdown': ?markdown,
      if (mindMap != null) 'mindMap': MindMapDto.body(mindMap),
    })).toDomain(),
  );

  @override
  Future<AppResult<SavedQuiz>> saveArtifactAsQuiz({
    required String subjectId,
    String? title,
    required List<QuestionDraft> questions,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.saveAsQuiz({
      'subjectId': subjectId,
      'title': ?title,
      'questions': questions.map(QuestionDraftDto.body).toList(),
    })).toDomain(),
  );
}
