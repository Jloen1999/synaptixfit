import '../../models/planner/planner_ai.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Propuesta de bloques de estudio y deporte para la semana.
abstract interface class SuggestWeekPlanUseCaseContract {
  Future<AppResult<WeekSuggestion>> call({
    required DateTime weekStart,
    required double studyHours,
    required int sportSessions,
  });
}

class SuggestWeekPlanUseCase implements SuggestWeekPlanUseCaseContract {
  const SuggestWeekPlanUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<WeekSuggestion>> call({
    required DateTime weekStart,
    required double studyHours,
    required int sportSessions,
  }) => _repository.suggestWeek(
    weekStart: weekStart,
    studyHours: studyHours,
    sportSessions: sportSessions,
  );
}
