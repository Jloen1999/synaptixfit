import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/note_draft_repository_contract.dart';

/// Borra el borrador de un apunte (al guardarlo o al descartarlo).
abstract interface class DiscardNoteDraftUseCaseContract {
  Future<AppResult<Unit>> call({required String accountId, String? noteId});
}

class DiscardNoteDraftUseCase implements DiscardNoteDraftUseCaseContract {
  const DiscardNoteDraftUseCase(this._repository);

  final NoteDraftRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({required String accountId, String? noteId}) =>
      _repository.discard(accountId: accountId, noteId: noteId);
}
