import '../../models/result/app_result.dart';
import '../../models/training/live_session_draft.dart';
import '../../repositories/live_session_draft_repository_contract.dart';

/// Cronómetro de la serie y cambios de hoy guardados en el teléfono para
/// una sesión (vacío si no hay).
abstract interface class LoadLiveSessionDraftUseCaseContract {
  Future<AppResult<LiveSessionDraft>> call(String sessionId);
}

class LoadLiveSessionDraftUseCase
    implements LoadLiveSessionDraftUseCaseContract {
  const LoadLiveSessionDraftUseCase(this._repository);

  final LiveSessionDraftRepositoryContract _repository;

  @override
  Future<AppResult<LiveSessionDraft>> call(String sessionId) =>
      _repository.load(sessionId);
}
