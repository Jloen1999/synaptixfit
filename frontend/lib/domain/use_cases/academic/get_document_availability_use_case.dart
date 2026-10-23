import '../../enums/study_source_type.dart';
import '../../models/academic/study_document.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_assistant_repository_contract.dart';

/// Documentos de IA guardados de una fuente.
abstract interface class GetDocumentAvailabilityUseCaseContract {
  Future<AppResult<DocumentAvailability>> call(
    StudySourceType sourceType,
    String sourceId,
  );
}

class GetDocumentAvailabilityUseCase
    implements GetDocumentAvailabilityUseCaseContract {
  const GetDocumentAvailabilityUseCase(this._repository);

  final StudyAssistantRepositoryContract _repository;

  @override
  Future<AppResult<DocumentAvailability>> call(
    StudySourceType sourceType,
    String sourceId,
  ) => _repository.getAvailability(sourceType, sourceId);
}
