import '../../enums/ai_document_type.dart';
import '../../enums/study_source_type.dart';
import '../../models/academic/study_document.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_assistant_repository_contract.dart';

/// Genera o regenera un documento de IA.
abstract interface class GenerateStudyDocumentUseCaseContract {
  Future<AppResult<StudyDocument>> call(
    StudySourceType sourceType,
    String sourceId,
    AiDocumentType type,
  );
}

class GenerateStudyDocumentUseCase
    implements GenerateStudyDocumentUseCaseContract {
  const GenerateStudyDocumentUseCase(this._repository);

  final StudyAssistantRepositoryContract _repository;

  @override
  Future<AppResult<StudyDocument>> call(
    StudySourceType sourceType,
    String sourceId,
    AiDocumentType type,
  ) => _repository.generateDocument(sourceType, sourceId, type);
}
