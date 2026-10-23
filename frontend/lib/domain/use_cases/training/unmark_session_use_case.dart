import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// Deshace la finalización de una sesión y resta su experiencia.
abstract interface class UnmarkSessionUseCaseContract {
  Future<AppResult<UnmarkSessionResult>> call(String sessionId);
}

class UnmarkSessionUseCase implements UnmarkSessionUseCaseContract {
  const UnmarkSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<UnmarkSessionResult>> call(String sessionId) =>
      _repository.unmarkSession(sessionId);
}
