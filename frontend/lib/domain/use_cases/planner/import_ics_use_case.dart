import '../../models/planner/planner_ai.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Importa el calendario ICS de una asignatura.
abstract interface class ImportIcsUseCaseContract {
  Future<AppResult<IcsImportResult>> call({
    required String subjectId,
    String? url,
    bool force = false,
  });
}

class ImportIcsUseCase implements ImportIcsUseCaseContract {
  const ImportIcsUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<IcsImportResult>> call({
    required String subjectId,
    String? url,
    bool force = false,
  }) => _repository.importIcs(subjectId: subjectId, url: url, force: force);
}
