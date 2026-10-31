import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/models/training/session.dart';
import '../../domain/repositories/pending_sets_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/pending_sets_storage.dart';

/// Implementa [PendingSetsRepositoryContract] con [PendingSetsStorage].
class PendingSetsRepository implements PendingSetsRepositoryContract {
  const PendingSetsRepository(this._storage);

  final PendingSetsStorage _storage;

  @override
  Future<AppResult<List<SetRecord>>> load(String sessionId) =>
      RepositoryErrorHandler.guard(() => _storage.load(sessionId));

  @override
  Future<AppResult<Unit>> save(String sessionId, List<SetRecord> sets) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.save(sessionId, sets);
        return unit;
      });
}
