import '../../models/result/app_result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// Entrenos de carrera en el calendario aún por hacer (hoy y la próxima semana).
abstract interface class ListPlannedRunsUseCaseContract {
  Future<AppResult<List<PlannedRun>>> call();
}

class ListPlannedRunsUseCase implements ListPlannedRunsUseCaseContract {
  const ListPlannedRunsUseCase(this._repository);

  final RunRepositoryContract _repository;

  @override
  Future<AppResult<List<PlannedRun>>> call() => _repository.listPlanned();
}
