import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/pending_sets_repository_contract.dart';

/// Series de una sesión guardadas en el teléfono sin conexión (vacía si no
/// hay).
abstract interface class LoadPendingSetsUseCaseContract {
  Future<AppResult<List<SetRecord>>> call(String sessionId);
}

class LoadPendingSetsUseCase implements LoadPendingSetsUseCaseContract {
  const LoadPendingSetsUseCase(this._repository);

  final PendingSetsRepositoryContract _repository;

  @override
  Future<AppResult<List<SetRecord>>> call(String sessionId) =>
      _repository.load(sessionId);
}
