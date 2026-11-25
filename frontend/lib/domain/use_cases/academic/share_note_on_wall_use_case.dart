import '../../models/academic/material_sharing.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// «Compartir › En el muro» (ADR 0064): el servidor publica el apunte (una
/// sola vez) y lo abre a quien ve el muro.
abstract interface class ShareNoteOnWallUseCaseContract {
  Future<AppResult<NoteWallShare>> call(String noteId);
}

class ShareNoteOnWallUseCase implements ShareNoteOnWallUseCaseContract {
  const ShareNoteOnWallUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<NoteWallShare>> call(String noteId) =>
      _repository.shareNoteOnWall(noteId);
}
