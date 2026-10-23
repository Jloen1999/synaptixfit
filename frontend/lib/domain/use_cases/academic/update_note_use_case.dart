import '../../enums/visibility.dart';
import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Edita un apunte.
abstract interface class UpdateNoteUseCaseContract {
  Future<AppResult<Note>> call(
    String noteId, {
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
    String? subjectId,
    bool detachSubject = false,
  });
}

class UpdateNoteUseCase implements UpdateNoteUseCaseContract {
  const UpdateNoteUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<Note>> call(
    String noteId, {
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
    String? subjectId,
    bool detachSubject = false,
  }) => _repository.updateNote(
    noteId,
    title: title,
    content: content,
    visibility: visibility,
    quickNote: quickNote,
    subjectId: subjectId,
    detachSubject: detachSubject,
  );
}
