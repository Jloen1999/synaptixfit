import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Apuntes compartidos por amigos.
abstract interface class GetSharedNotesUseCaseContract {
  Future<AppResult<SharedNotesPage>> call({required int page});
}

class GetSharedNotesUseCase implements GetSharedNotesUseCaseContract {
  const GetSharedNotesUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<SharedNotesPage>> call({required int page}) =>
      _repository.getSharedNotes(page: page);
}
