import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../models/training/live_session_draft.dart';
import '../../repositories/live_session_draft_repository_contract.dart';

/// Guarda en el teléfono el cronómetro de la serie y los cambios de hoy de
/// una sesión; vacío, lo borra.
abstract interface class SaveLiveSessionDraftUseCaseContract {
  Future<AppResult<Unit>> call(String sessionId, LiveSessionDraft draft);
}

class SaveLiveSessionDraftUseCase
    implements SaveLiveSessionDraftUseCaseContract {
  const SaveLiveSessionDraftUseCase(this._repository);

  final LiveSessionDraftRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String sessionId, LiveSessionDraft draft) =>
      _repository.save(sessionId, draft);
}
