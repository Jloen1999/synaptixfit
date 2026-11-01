import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Lleva un apunte a una asignatura sin tocar su texto ni su visibilidad
/// («Mover a asignatura» desde la bandeja de notas).
abstract interface class MoveNoteToSubjectUseCaseContract {
  Future<AppResult<Note>> call(String noteId, {required String subjectId});
}

class MoveNoteToSubjectUseCase implements MoveNoteToSubjectUseCaseContract {
  const MoveNoteToSubjectUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<Note>> call(String noteId, {required String subjectId}) =>
      _repository.moveNoteToSubject(noteId, subjectId: subjectId);
}
