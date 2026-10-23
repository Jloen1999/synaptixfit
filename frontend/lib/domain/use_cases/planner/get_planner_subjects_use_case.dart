import '../../models/planner/planner_options.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Asignaturas activas para elegir en el planner.
abstract interface class GetPlannerSubjectsUseCaseContract {
  Future<AppResult<List<SubjectOption>>> call();
}

class GetPlannerSubjectsUseCase implements GetPlannerSubjectsUseCaseContract {
  const GetPlannerSubjectsUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<List<SubjectOption>>> call() => _repository.getSubjects();
}
