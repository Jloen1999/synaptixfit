import '../../models/result/app_result.dart';
import '../../models/training/session_history.dart';
import '../../models/training/training_page.dart';
import '../../repositories/training_history_repository_contract.dart';

/// Historial de sesiones completadas con su nombre y los récords batidos.
abstract interface class GetSessionHistoryUseCaseContract {
  Future<AppResult<TrainingPage<SessionHistoryEntry>>> call({
    int page = 0,
    int size = 20,
  });
}

class GetSessionHistoryUseCase implements GetSessionHistoryUseCaseContract {
  const GetSessionHistoryUseCase(this._repository);

  final TrainingHistoryRepositoryContract _repository;

  @override
  Future<AppResult<TrainingPage<SessionHistoryEntry>>> call({
    int page = 0,
    int size = 20,
  }) => _repository.getHistory(page: page, size: size);
}
