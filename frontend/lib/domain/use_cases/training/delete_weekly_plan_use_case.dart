import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/training_repository_contract.dart';

/// Elimina el plan semanal.
abstract interface class DeleteWeeklyPlanUseCaseContract {
  Future<AppResult<Unit>> call(DateTime weekStart);
}

class DeleteWeeklyPlanUseCase implements DeleteWeeklyPlanUseCaseContract {
  const DeleteWeeklyPlanUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(DateTime weekStart) =>
      _repository.deleteWeeklyPlan(weekStart);
}
