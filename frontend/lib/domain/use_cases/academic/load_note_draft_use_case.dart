import '../../models/academic/note_draft.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_draft_repository_contract.dart';

/// Borrador sin guardar de un apunte (nulo = apunte nuevo), o null si no hay.
abstract interface class LoadNoteDraftUseCaseContract {
  Future<AppResult<NoteDraft?>> call({
    required String accountId,
    String? noteId,
  });
}

class LoadNoteDraftUseCase implements LoadNoteDraftUseCaseContract {
  const LoadNoteDraftUseCase(this._repository);

  final NoteDraftRepositoryContract _repository;

  @override
  Future<AppResult<NoteDraft?>> call({
    required String accountId,
    String? noteId,
  }) => _repository.load(accountId: accountId, noteId: noteId);
}
