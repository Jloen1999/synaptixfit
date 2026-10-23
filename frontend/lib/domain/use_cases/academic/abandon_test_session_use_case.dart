import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Abandona el simulacro.
abstract interface class AbandonTestSessionUseCaseContract {
  Future<AppResult<TestSession>> call(String sessionId);
}

class AbandonTestSessionUseCase implements AbandonTestSessionUseCaseContract {
  const AbandonTestSessionUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<TestSession>> call(String sessionId) =>
      _repository.abandonTestSession(sessionId);
}
