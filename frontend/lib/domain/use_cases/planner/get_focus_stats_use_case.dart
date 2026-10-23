import '../../models/planner/focus.dart';
import '../../models/result/app_result.dart';
import '../../repositories/focus_repository_contract.dart';

/// Estadísticas Pomodoro de hoy y de la semana.
abstract interface class GetFocusStatsUseCaseContract {
  Future<AppResult<FocusStats>> call();
}

class GetFocusStatsUseCase implements GetFocusStatsUseCaseContract {
  const GetFocusStatsUseCase(this._repository);

  final FocusRepositoryContract _repository;

  @override
  Future<AppResult<FocusStats>> call() => _repository.getStats();
}
