import '../../enums/ai_document_type.dart';
import '../../enums/study_source_type.dart';
import '../../models/academic/study_document.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/study_assistant_repository_contract.dart';
import 'get_teaching_guide_use_case.dart';

/// Devuelve el documento de IA guardado y, si no existe, lo genera.
abstract interface class LoadOrGenerateStudyDocumentUseCaseContract {
  Future<AppResult<StudyDocument>> call(
    StudySourceType sourceType,
    String sourceId,
    AiDocumentType type,
  );
}

class LoadOrGenerateStudyDocumentUseCase
    implements LoadOrGenerateStudyDocumentUseCaseContract {
  const LoadOrGenerateStudyDocumentUseCase(this._repository);

  final StudyAssistantRepositoryContract _repository;

  @override
  Future<AppResult<StudyDocument>> call(
    StudySourceType sourceType,
    String sourceId,
    AiDocumentType type,
  ) async {
    final saved = await _repository.getDocument(sourceType, sourceId, type);
    if (saved case Failure(:final error) when isMissingStudyDocument(error)) {
      return _repository.generateDocument(sourceType, sourceId, type);
    }
    return saved;
  }
}
