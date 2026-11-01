import '../../domain/models/academic/note_draft.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/note_draft_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/note_draft_storage.dart';

/// Implementa [NoteDraftRepositoryContract] con [NoteDraftStorage].
class NoteDraftRepository implements NoteDraftRepositoryContract {
  const NoteDraftRepository(this._storage);

  final NoteDraftStorage _storage;

  @override
  Future<AppResult<NoteDraft?>> load({
    required String accountId,
    String? noteId,
  }) => RepositoryErrorHandler.guard(
    () => _storage.load(accountId: accountId, noteId: noteId),
  );

  @override
  Future<AppResult<Unit>> save(NoteDraft draft) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.save(draft);
        return unit;
      });

  @override
  Future<AppResult<Unit>> discard({
    required String accountId,
    String? noteId,
  }) => RepositoryErrorHandler.guard(() async {
    await _storage.discard(accountId: accountId, noteId: noteId);
    return unit;
  });
}
