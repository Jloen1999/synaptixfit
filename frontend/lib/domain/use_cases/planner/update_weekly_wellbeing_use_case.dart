import '../../models/planner/weekly_planning.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Registra estrés, sueño y notas de la semana.
abstract interface class UpdateWeeklyWellbeingUseCaseContract {
  Future<AppResult<WeeklyLoad>> call(
    DateTime weekStart, {
    int? stressLevel,
    double? sleepHours,
    String? notes,
  });
}

class UpdateWeeklyWellbeingUseCase
    implements UpdateWeeklyWellbeingUseCaseContract {
  const UpdateWeeklyWellbeingUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<WeeklyLoad>> call(
    DateTime weekStart, {
    int? stressLevel,
    double? sleepHours,
    String? notes,
  }) => _repository.updateWellbeing(
    weekStart,
    stressLevel: stressLevel,
    sleepHours: sleepHours,
    notes: notes,
  );
}
