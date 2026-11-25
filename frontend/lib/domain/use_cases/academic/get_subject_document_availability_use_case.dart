import '../../models/academic/study_document.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_assistant_repository_contract.dart';

/// Documentos de IA guardados de todo el material de una asignatura, en una
/// sola petición (ADR 0064), por id de apunte o archivo.
abstract interface class GetSubjectDocumentAvailabilityUseCaseContract {
  Future<AppResult<Map<String, DocumentAvailability>>> call(String subjectId);
}

class GetSubjectDocumentAvailabilityUseCase
    implements GetSubjectDocumentAvailabilityUseCaseContract {
  const GetSubjectDocumentAvailabilityUseCase(this._repository);

  final StudyAssistantRepositoryContract _repository;

  @override
  Future<AppResult<Map<String, DocumentAvailability>>> call(
    String subjectId,
  ) => _repository.getSubjectAvailability(subjectId);
}
