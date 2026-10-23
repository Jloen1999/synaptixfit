import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Genera con IA el banco de preguntas de un material.
abstract interface class GenerateQuestionBankUseCaseContract {
  Future<AppResult<QuestionBank>> call(String materialId);
}

class GenerateQuestionBankUseCase
    implements GenerateQuestionBankUseCaseContract {
  const GenerateQuestionBankUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<QuestionBank>> call(String materialId) =>
      _repository.generateQuestionBank(materialId);
}
