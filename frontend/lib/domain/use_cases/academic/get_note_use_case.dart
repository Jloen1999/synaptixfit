import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Un apunte.
abstract interface class GetNoteUseCaseContract {
  Future<AppResult<Note>> call(String noteId);
}

class GetNoteUseCase implements GetNoteUseCaseContract {
  const GetNoteUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<Note>> call(String noteId) => _repository.getNote(noteId);
}
