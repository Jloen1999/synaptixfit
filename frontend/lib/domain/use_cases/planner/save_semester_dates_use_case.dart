import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Guarda las fechas de inicio y fin de clases.
abstract interface class SaveSemesterDatesUseCaseContract {
  Future<AppResult<Unit>> call({
    required DateTime start,
    required DateTime end,
  });
}

class SaveSemesterDatesUseCase implements SaveSemesterDatesUseCaseContract {
  const SaveSemesterDatesUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({
    required DateTime start,
    required DateTime end,
  }) => _repository.saveSemesterDates(start: start, end: end);
}
