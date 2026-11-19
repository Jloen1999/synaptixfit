import '../../models/academic/question_creation.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Busca las preguntas que ya trae escritas el apunte o archivo de un
/// material, para revisarlas antes de guardarlas (ADR 0058).
abstract interface class ScanDocumentQuestionsUseCaseContract {
  Future<AppResult<DocumentQuestionScan>> call(String materialId);
}

class ScanDocumentQuestionsUseCase
    implements ScanDocumentQuestionsUseCaseContract {
  const ScanDocumentQuestionsUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<DocumentQuestionScan>> call(String materialId) =>
      _repository.scanDocumentQuestions(materialId);
}
