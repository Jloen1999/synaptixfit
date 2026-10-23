import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Termina el simulacro y otorga la XP.
abstract interface class CompleteTestSessionUseCaseContract {
  Future<AppResult<TestSession>> call(String sessionId);
}

class CompleteTestSessionUseCase implements CompleteTestSessionUseCaseContract {
  const CompleteTestSessionUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<TestSession>> call(String sessionId) =>
      _repository.completeTestSession(sessionId);
}
