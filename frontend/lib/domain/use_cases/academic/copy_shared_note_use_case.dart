import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Guarda una copia privada de un apunte compartido en mis apuntes (en mi
/// asignatura equivalente, si la tengo). Devuelve la copia.
abstract interface class CopySharedNoteUseCaseContract {
  Future<AppResult<Note>> call(String noteId);
}

class CopySharedNoteUseCase implements CopySharedNoteUseCaseContract {
  const CopySharedNoteUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<Note>> call(String noteId) =>
      _repository.copySharedNote(noteId);
}
