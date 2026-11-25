import '../../enums/visibility.dart';
import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// «Compartir › Para todos» (ADR 0064): el apunte pasa a público y sale en
/// «Apuntes compartidos». El servidor lo rebaja al tope del perfil; la
/// visibilidad con la que queda viene en el apunte devuelto.
abstract interface class ShareNoteWithEveryoneUseCaseContract {
  Future<AppResult<Note>> call(String noteId);
}

class ShareNoteWithEveryoneUseCase
    implements ShareNoteWithEveryoneUseCaseContract {
  const ShareNoteWithEveryoneUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<Note>> call(String noteId) =>
      _repository.setNoteVisibility(noteId, Visibility.public);
}
