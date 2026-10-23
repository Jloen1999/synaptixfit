import '../../models/result/app_result.dart';
import '../../models/training/wellbeing.dart';
import '../../repositories/training_repository_contract.dart';

/// Crea o actualiza el plan semanal.
abstract interface class SaveWeeklyPlanUseCaseContract {
  Future<AppResult<WeeklyPlan>> call(DateTime weekStart, WeeklyPlanInput input);
}

class SaveWeeklyPlanUseCase implements SaveWeeklyPlanUseCaseContract {
  const SaveWeeklyPlanUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<WeeklyPlan>> call(
    DateTime weekStart,
    WeeklyPlanInput input,
  ) => _repository.saveWeeklyPlan(weekStart, input);
}
