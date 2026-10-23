import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Historial de simulacros de un material.
abstract interface class GetTestSessionsUseCaseContract {
  Future<AppResult<List<TestSessionSummary>>> call(String materialId);
}

class GetTestSessionsUseCase implements GetTestSessionsUseCaseContract {
  const GetTestSessionsUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<List<TestSessionSummary>>> call(String materialId) =>
      _repository.getTestSessions(materialId);
}
