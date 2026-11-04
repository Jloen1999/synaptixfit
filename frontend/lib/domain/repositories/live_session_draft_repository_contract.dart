import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/training/live_session_draft.dart';

/// Estado de una sesión en curso que solo vive en el teléfono
/// ([LiveSessionDraft]), por sesión.
abstract interface class LiveSessionDraftRepositoryContract {
  /// Vacío si no hay nada guardado.
  Future<AppResult<LiveSessionDraft>> load(String sessionId);

  /// Sustituye lo guardado; un borrador vacío lo borra.
  Future<AppResult<Unit>> save(String sessionId, LiveSessionDraft draft);
}
