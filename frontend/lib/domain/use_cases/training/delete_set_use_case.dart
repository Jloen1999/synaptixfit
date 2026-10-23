import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// Borra una serie registrada.
abstract interface class DeleteSetUseCaseContract {
  Future<AppResult<TrainingSession>> call(String sessionId, String setId);
}

class DeleteSetUseCase implements DeleteSetUseCaseContract {
  const DeleteSetUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingSession>> call(String sessionId, String setId) =>
      _repository.deleteSet(sessionId, setId);
}
