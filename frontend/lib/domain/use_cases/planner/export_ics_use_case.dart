import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Exporta el calendario del usuario como texto `.ics`.
abstract interface class ExportIcsUseCaseContract {
  Future<AppResult<String>> call();
}

class ExportIcsUseCase implements ExportIcsUseCaseContract {
  const ExportIcsUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<String>> call() => _repository.exportIcs();
}
