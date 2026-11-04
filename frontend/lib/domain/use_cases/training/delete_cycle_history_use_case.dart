import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Borra todo lo apuntado del ciclo.
abstract interface class DeleteCycleHistoryUseCaseContract {
  Future<AppResult<Unit>> call();
}

class DeleteCycleHistoryUseCase implements DeleteCycleHistoryUseCaseContract {
  const DeleteCycleHistoryUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call() => _repository.deleteCycleHistory();
}
