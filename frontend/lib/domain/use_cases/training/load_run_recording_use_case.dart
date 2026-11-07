import '../../models/result/app_result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// Carrera en curso guardada en el teléfono (nula si no hay).
abstract interface class LoadRunRecordingUseCaseContract {
  Future<AppResult<RunRecording?>> call();
}

class LoadRunRecordingUseCase implements LoadRunRecordingUseCaseContract {
  const LoadRunRecordingUseCase(this._repository);

  final RunRecordingRepositoryContract _repository;

  @override
  Future<AppResult<RunRecording?>> call() => _repository.loadCurrent();
}
