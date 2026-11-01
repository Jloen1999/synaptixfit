import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/training_repository_contract.dart';

/// Abandona o descarta una sesión sin terminar (se borran sus series). Usa la
/// misma llamada que [DeleteSessionUseCaseContract], pero es otra intención: esta
/// nunca toca XP ni carga porque la sesión no se llegó a terminar.
abstract interface class CancelSessionUseCaseContract {
  Future<AppResult<Unit>> call(String sessionId);
}

class CancelSessionUseCase implements CancelSessionUseCaseContract {
  const CancelSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String sessionId) =>
      _repository.deleteSession(sessionId);
}
