import '../../models/planner/active_focus_timer.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/active_focus_timer_repository_contract.dart';

/// Guarda la fase del Pomodoro en curso (sustituye a la anterior).
abstract interface class SaveActiveFocusTimerUseCaseContract {
  Future<AppResult<Unit>> call(ActiveFocusTimer timer);
}

class SaveActiveFocusTimerUseCase
    implements SaveActiveFocusTimerUseCaseContract {
  const SaveActiveFocusTimerUseCase(this._repository);

  final ActiveFocusTimerRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(ActiveFocusTimer timer) =>
      _repository.save(timer);
}
