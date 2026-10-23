import '../../models/profile/wellness_history.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Historial de objetivos.
abstract interface class GetGoalHistoryUseCaseContract {
  Future<AppResult<List<GoalHistoryEntry>>> call();
}

class GetGoalHistoryUseCase implements GetGoalHistoryUseCaseContract {
  const GetGoalHistoryUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<List<GoalHistoryEntry>>> call() =>
      _repository.getGoalHistory();
}
