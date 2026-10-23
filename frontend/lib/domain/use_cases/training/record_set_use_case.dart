import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// Registra (o sustituye) una serie en una sesión en curso.
abstract interface class RecordSetUseCaseContract {
  Future<AppResult<TrainingSession>> call(String sessionId, SetRecord record);
}

class RecordSetUseCase implements RecordSetUseCaseContract {
  const RecordSetUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingSession>> call(String sessionId, SetRecord record) =>
      _repository.recordSet(sessionId, record);
}
