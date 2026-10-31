import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../models/training/session.dart';
import '../../repositories/pending_sets_repository_contract.dart';

/// Guarda en el teléfono las series que esperan conexión (vacía = borrarlas).
abstract interface class SavePendingSetsUseCaseContract {
  Future<AppResult<Unit>> call(String sessionId, List<SetRecord> sets);
}

class SavePendingSetsUseCase implements SavePendingSetsUseCaseContract {
  const SavePendingSetsUseCase(this._repository);

  final PendingSetsRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String sessionId, List<SetRecord> sets) =>
      _repository.save(sessionId, sets);
}
