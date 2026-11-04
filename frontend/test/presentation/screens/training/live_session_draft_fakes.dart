import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/live_session_draft.dart';
import 'package:synaptixfit/domain/use_cases/training/load_live_session_draft_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/save_live_session_draft_use_case.dart';

/// Borradores de sesión en memoria: lo que guardaría el teléfono, compartido
/// por los dos casos de uso falsos para probar que sobreviven a reabrir.
class DraftStore {
  final Map<String, LiveSessionDraft> drafts = {};
}

class FakeLoadDraft implements LoadLiveSessionDraftUseCaseContract {
  FakeLoadDraft([DraftStore? store]) : store = store ?? DraftStore();

  final DraftStore store;

  @override
  Future<AppResult<LiveSessionDraft>> call(String sessionId) async =>
      Success(store.drafts[sessionId] ?? const LiveSessionDraft());
}

class FakeSaveDraft implements SaveLiveSessionDraftUseCaseContract {
  FakeSaveDraft([DraftStore? store]) : store = store ?? DraftStore();

  final DraftStore store;

  @override
  Future<AppResult<Unit>> call(String sessionId, LiveSessionDraft draft) async {
    if (draft.isEmpty) {
      store.drafts.remove(sessionId);
    } else {
      store.drafts[sessionId] = draft;
    }
    return const Success(unit);
  }
}
