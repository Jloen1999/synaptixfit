import '../../enums/visibility.dart';
import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Crea un apunte.
abstract interface class CreateNoteUseCaseContract {
  Future<AppResult<Note>> call({
    String? subjectId,
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
  });
}

class CreateNoteUseCase implements CreateNoteUseCaseContract {
  const CreateNoteUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<Note>> call({
    String? subjectId,
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
  }) => _repository.createNote(
    subjectId: subjectId,
    title: title,
    content: content,
    visibility: visibility,
    quickNote: quickNote,
  );
}
