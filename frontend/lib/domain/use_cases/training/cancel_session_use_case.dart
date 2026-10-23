import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/training_repository_contract.dart';

/// Abandona una sesión en curso.
abstract interface class CancelSessionUseCaseContract {
  Future<AppResult<Unit>> call(String sessionId);
}

class CancelSessionUseCase implements CancelSessionUseCaseContract {
  const CancelSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String sessionId) =>
      _repository.cancelSession(sessionId);
}
