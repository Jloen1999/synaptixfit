import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/active_focus_timer_repository_contract.dart';

/// Olvida la fase del Pomodoro guardada (terminó, se reinició o se cerró sesión).
abstract interface class ClearActiveFocusTimerUseCaseContract {
  Future<AppResult<Unit>> call();
}

class ClearActiveFocusTimerUseCase
    implements ClearActiveFocusTimerUseCaseContract {
  const ClearActiveFocusTimerUseCase(this._repository);

  final ActiveFocusTimerRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call() => _repository.clear();
}
