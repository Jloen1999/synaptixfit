import '../../models/result/app_result.dart';
import '../../models/training/wellbeing.dart';
import '../../repositories/training_repository_contract.dart';

/// Plan semanal de entrenamiento (o null si no hay).
abstract interface class GetWeeklyPlanUseCaseContract {
  Future<AppResult<WeeklyPlan?>> call(DateTime weekStart);
}

class GetWeeklyPlanUseCase implements GetWeeklyPlanUseCaseContract {
  const GetWeeklyPlanUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<WeeklyPlan?>> call(DateTime weekStart) =>
      _repository.getWeeklyPlan(weekStart);
}
