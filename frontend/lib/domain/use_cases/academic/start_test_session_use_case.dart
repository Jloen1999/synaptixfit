import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Empieza un simulacro.
abstract interface class StartTestSessionUseCaseContract {
  Future<AppResult<TestSession>> call(
    List<String> materialIds, {
    int? questionCount,
  });
}

class StartTestSessionUseCase implements StartTestSessionUseCaseContract {
  const StartTestSessionUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<TestSession>> call(
    List<String> materialIds, {
    int? questionCount,
  }) => _repository.startTestSession(materialIds, questionCount: questionCount);
}
