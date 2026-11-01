import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Un apunte compartido completo (si ya no se puede ver, `NOTE_NOT_FOUND`).
abstract interface class GetSharedNoteUseCaseContract {
  Future<AppResult<SharedNote>> call(String noteId);
}

class GetSharedNoteUseCase implements GetSharedNoteUseCaseContract {
  const GetSharedNoteUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<SharedNote>> call(String noteId) =>
      _repository.getSharedNote(noteId);
}
