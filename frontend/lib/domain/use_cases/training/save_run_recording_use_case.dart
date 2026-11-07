import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// Guarda en el teléfono la carrera en curso (cada pocos puntos).
abstract interface class SaveRunRecordingUseCaseContract {
  Future<AppResult<Unit>> call(RunRecording recording);
}

class SaveRunRecordingUseCase implements SaveRunRecordingUseCaseContract {
  const SaveRunRecordingUseCase(this._repository);

  final RunRecordingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(RunRecording recording) =>
      _repository.saveCurrent(recording);
}
