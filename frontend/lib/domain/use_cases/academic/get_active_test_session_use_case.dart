import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Simulacro en curso del material, si lo hay.
abstract interface class GetActiveTestSessionUseCaseContract {
  Future<AppResult<TestSession?>> call(String materialId);
}

class GetActiveTestSessionUseCase
    implements GetActiveTestSessionUseCaseContract {
  const GetActiveTestSessionUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<TestSession?>> call(String materialId) =>
      _repository.getActiveTestSession(materialId);
}
