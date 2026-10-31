import '../../models/result/app_result.dart';
import '../../models/training/session_history.dart';
import '../../repositories/training_history_repository_contract.dart';

/// Resumen destacado de una sesión terminada: volumen, récords batidos y
/// comparación con la anterior comparable (lo calcula el servidor).
abstract interface class GetSessionHighlightsUseCaseContract {
  Future<AppResult<SessionHighlights>> call(String sessionId);
}

class GetSessionHighlightsUseCase
    implements GetSessionHighlightsUseCaseContract {
  const GetSessionHighlightsUseCase(this._repository);

  final TrainingHistoryRepositoryContract _repository;

  @override
  Future<AppResult<SessionHighlights>> call(String sessionId) =>
      _repository.getSessionHighlights(sessionId);
}
