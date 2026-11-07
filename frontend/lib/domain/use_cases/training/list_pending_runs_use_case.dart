import '../../models/result/app_result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// Carreras terminadas que esperan conexión para subirse.
abstract interface class ListPendingRunsUseCaseContract {
  Future<AppResult<List<RunRecording>>> call();
}

class ListPendingRunsUseCase implements ListPendingRunsUseCaseContract {
  const ListPendingRunsUseCase(this._repository);

  final RunRecordingRepositoryContract _repository;

  @override
  Future<AppResult<List<RunRecording>>> call() => _repository.pending();
}
