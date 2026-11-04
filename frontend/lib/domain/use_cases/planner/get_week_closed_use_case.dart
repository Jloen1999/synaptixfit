import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// ¿Ya se cerró la semana de [weekStart]? «Cerrar semana» se hace una vez:
/// después la app enseña «Semana cerrada» en lugar del botón.
abstract interface class GetWeekClosedUseCaseContract {
  Future<AppResult<bool>> call(DateTime weekStart);
}

class GetWeekClosedUseCase implements GetWeekClosedUseCaseContract {
  const GetWeekClosedUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<bool>> call(DateTime weekStart) =>
      _repository.isWeekClosed(weekStart);
}
