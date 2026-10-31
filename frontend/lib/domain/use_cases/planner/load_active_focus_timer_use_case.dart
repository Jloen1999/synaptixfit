import '../../models/planner/active_focus_timer.dart';
import '../../models/result/app_result.dart';
import '../../repositories/active_focus_timer_repository_contract.dart';

/// Fase del Pomodoro que quedó en marcha o en pausa (null si no hay).
abstract interface class LoadActiveFocusTimerUseCaseContract {
  Future<AppResult<ActiveFocusTimer?>> call();
}

class LoadActiveFocusTimerUseCase
    implements LoadActiveFocusTimerUseCaseContract {
  const LoadActiveFocusTimerUseCase(this._repository);

  final ActiveFocusTimerRepositoryContract _repository;

  @override
  Future<AppResult<ActiveFocusTimer?>> call() => _repository.load();
}
