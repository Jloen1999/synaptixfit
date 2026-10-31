import '../../models/result/app_result.dart';
import '../../models/training/session_adaptation.dart';
import '../../repositories/training_repository_contract.dart';

/// Cómo se adapta hoy una sesión por examen cercano, carga alta o fatiga.
abstract interface class GetSessionAdaptationUseCaseContract {
  Future<AppResult<SessionAdaptation>> call(String sessionId);
}

class GetSessionAdaptationUseCase
    implements GetSessionAdaptationUseCaseContract {
  const GetSessionAdaptationUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<SessionAdaptation>> call(String sessionId) =>
      _repository.getSessionAdaptation(sessionId);
}
