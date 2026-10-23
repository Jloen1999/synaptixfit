import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Responde una pregunta del simulacro.
abstract interface class AnswerInTestSessionUseCaseContract {
  Future<AppResult<SessionAnswer>> call(
    String sessionId, {
    required String questionId,
    required String answer,
    int? nextIndex,
  });
}

class AnswerInTestSessionUseCase implements AnswerInTestSessionUseCaseContract {
  const AnswerInTestSessionUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<SessionAnswer>> call(
    String sessionId, {
    required String questionId,
    required String answer,
    int? nextIndex,
  }) => _repository.answerInSession(
    sessionId,
    questionId: questionId,
    answer: answer,
    nextIndex: nextIndex,
  );
}
