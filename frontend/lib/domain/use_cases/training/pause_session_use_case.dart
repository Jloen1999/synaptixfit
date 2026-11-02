import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// Pausa una sesión en curso: el tiempo en pausa no cuenta para la carga ni las kcal.
abstract interface class PauseSessionUseCaseContract {
  Future<AppResult<TrainingSession>> call(String sessionId);
}

class PauseSessionUseCase implements PauseSessionUseCaseContract {
  const PauseSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingSession>> call(String sessionId) =>
      _repository.pauseSession(sessionId);
}
