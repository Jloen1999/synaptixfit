import '../models/academic/note_draft.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Borradores de apuntes guardados en el teléfono (uno por cuenta y apunte).
abstract interface class NoteDraftRepositoryContract {
  /// El borrador de [noteId] (nulo = apunte nuevo) o null si no hay.
  Future<AppResult<NoteDraft?>> load({
    required String accountId,
    String? noteId,
  });

  /// Sustituye el borrador anterior del mismo apunte.
  Future<AppResult<Unit>> save(NoteDraft draft);

  Future<AppResult<Unit>> discard({required String accountId, String? noteId});
}
