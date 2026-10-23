import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/note_repository_contract.dart';

/// Borra un apunte.
abstract interface class DeleteNoteUseCaseContract {
  Future<AppResult<Unit>> call(String noteId);
}

class DeleteNoteUseCase implements DeleteNoteUseCaseContract {
  const DeleteNoteUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String noteId) => _repository.deleteNote(noteId);
}
