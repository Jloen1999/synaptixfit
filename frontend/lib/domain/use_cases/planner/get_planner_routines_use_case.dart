import '../../models/planner/planner_options.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Rutinas del usuario para distribuir o vincular.
abstract interface class GetPlannerRoutinesUseCaseContract {
  Future<AppResult<List<RoutineOption>>> call();
}

class GetPlannerRoutinesUseCase implements GetPlannerRoutinesUseCaseContract {
  const GetPlannerRoutinesUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<List<RoutineOption>>> call() => _repository.getRoutines();
}
