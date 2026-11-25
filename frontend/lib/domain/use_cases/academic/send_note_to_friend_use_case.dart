import '../../models/academic/material_sharing.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// «Compartir › Con un amigo» (ADR 0064): el amigo puede leer el apunte y le
/// llega un aviso. Quién es amigo lo decide el servidor.
abstract interface class SendNoteToFriendUseCaseContract {
  Future<AppResult<SentNote>> call(String noteId, String friendId);
}

class SendNoteToFriendUseCase implements SendNoteToFriendUseCaseContract {
  const SendNoteToFriendUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<SentNote>> call(String noteId, String friendId) =>
      _repository.sendNoteToFriend(noteId, friendId);
}
