import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// «No lo sé» a una pregunta fuera del simulacro (ADR 0063): el servidor lo
/// cuenta como fallo, la pregunta vuelve antes y devuelve la solución.
abstract interface class DontKnowQuestionUseCaseContract {
  Future<AppResult<AnswerResult>> call(String questionId);
}

class DontKnowQuestionUseCase implements DontKnowQuestionUseCaseContract {
  const DontKnowQuestionUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<AnswerResult>> call(String questionId) =>
      _repository.dontKnowQuestion(questionId);
}
