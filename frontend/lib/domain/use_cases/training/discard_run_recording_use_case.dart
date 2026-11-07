import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/run_repository_contract.dart';

/// Olvida la carrera en curso sin guardarla.
abstract interface class DiscardRunRecordingUseCaseContract {
  Future<AppResult<Unit>> call();
}

class DiscardRunRecordingUseCase implements DiscardRunRecordingUseCaseContract {
  const DiscardRunRecordingUseCase(this._repository);

  final RunRecordingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call() => _repository.saveCurrent(null);
}
