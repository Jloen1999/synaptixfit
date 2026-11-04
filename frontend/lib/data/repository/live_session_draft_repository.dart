import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/models/training/live_session_draft.dart';
import '../../domain/repositories/live_session_draft_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/live_session_draft_storage.dart';

/// Implementa [LiveSessionDraftRepositoryContract] con
/// [LiveSessionDraftStorage].
class LiveSessionDraftRepository implements LiveSessionDraftRepositoryContract {
  const LiveSessionDraftRepository(this._storage);

  final LiveSessionDraftStorage _storage;

  @override
  Future<AppResult<LiveSessionDraft>> load(String sessionId) =>
      RepositoryErrorHandler.guard(() => _storage.load(sessionId));

  @override
  Future<AppResult<Unit>> save(String sessionId, LiveSessionDraft draft) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.save(sessionId, draft);
        return unit;
      });
}
