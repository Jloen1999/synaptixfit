import '../../enums/shared_notes_scope.dart';
import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Apuntes que otros usuarios comparten y puedo leer, por ámbito (amigos o
/// comunidad) o de un autor ([authorId]).
abstract interface class GetSharedNotesUseCaseContract {
  Future<AppResult<SharedNoteSummaryPage>> call({
    required int page,
    SharedNotesScope scope = SharedNotesScope.all,
    String? authorId,
    int size = 20,
  });
}

class GetSharedNotesUseCase implements GetSharedNotesUseCaseContract {
  const GetSharedNotesUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<SharedNoteSummaryPage>> call({
    required int page,
    SharedNotesScope scope = SharedNotesScope.all,
    String? authorId,
    int size = 20,
  }) => _repository.getSharedNotes(
    page: page,
    scope: scope,
    authorId: authorId,
    size: size,
  );
}
