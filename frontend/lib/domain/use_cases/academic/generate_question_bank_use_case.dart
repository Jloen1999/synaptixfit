import '../../models/academic/question_creation.dart';
import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// «Crear preguntas» de un material (ADR 0058): guarda las del documento que
/// se revisaron y crea con IA las nuevas, añadiéndolas o cambiando las de antes.
abstract interface class GenerateQuestionBankUseCaseContract {
  Future<AppResult<QuestionBank>> call(
    String materialId,
    CreateQuestionsRequest request,
  );
}

class GenerateQuestionBankUseCase
    implements GenerateQuestionBankUseCaseContract {
  const GenerateQuestionBankUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<QuestionBank>> call(
    String materialId,
    CreateQuestionsRequest request,
  ) => _repository.generateQuestionBank(materialId, request);
}
