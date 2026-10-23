import '../../models/planner/focus.dart';
import '../../models/result/app_result.dart';
import '../../repositories/focus_repository_contract.dart';

/// Duraciones recomendadas para el Pomodoro de hoy.
abstract interface class GetFocusPlanUseCaseContract {
  Future<AppResult<FocusPlan>> call();
}

class GetFocusPlanUseCase implements GetFocusPlanUseCaseContract {
  const GetFocusPlanUseCase(this._repository);

  final FocusRepositoryContract _repository;

  @override
  Future<AppResult<FocusPlan>> call() => _repository.getPlan();
}
