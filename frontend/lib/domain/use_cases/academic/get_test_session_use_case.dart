import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Una sesión de test.
abstract interface class GetTestSessionUseCaseContract {
  Future<AppResult<TestSession>> call(String sessionId);
}

class GetTestSessionUseCase implements GetTestSessionUseCaseContract {
  const GetTestSessionUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<TestSession>> call(String sessionId) =>
      _repository.getTestSession(sessionId);
}
