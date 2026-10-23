import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// Detalle de una sesión.
abstract interface class GetSessionUseCaseContract {
  Future<AppResult<TrainingSession>> call(String sessionId);
}

class GetSessionUseCase implements GetSessionUseCaseContract {
  const GetSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingSession>> call(String sessionId) =>
      _repository.getSession(sessionId);
}
