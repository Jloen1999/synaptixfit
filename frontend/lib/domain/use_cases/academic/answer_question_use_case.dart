import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Corrige una respuesta de la práctica libre.
abstract interface class AnswerQuestionUseCaseContract {
  Future<AppResult<AnswerResult>> call(String questionId, String answer);
}

class AnswerQuestionUseCase implements AnswerQuestionUseCaseContract {
  const AnswerQuestionUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<AnswerResult>> call(String questionId, String answer) =>
      _repository.answerQuestion(questionId, answer);
}
