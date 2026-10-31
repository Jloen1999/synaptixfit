import '../enums/visibility.dart';
import '../models/academic/note.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Apuntes propios y compartidos.
abstract interface class NoteRepositoryContract {
  Future<AppResult<List<Note>>> getNotes({String? subjectId});

  Future<AppResult<Note>> getNote(String noteId);

  Future<AppResult<Note>> createNote({
    String? subjectId,
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
  });

  /// [subjectId] nulo con [detachSubject] desvincula el apunte de la asignatura.
  Future<AppResult<Note>> updateNote(
    String noteId, {
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
    String? subjectId,
    bool detachSubject = false,
  });

  Future<AppResult<Unit>> deleteNote(String noteId);

  Future<AppResult<SharedNotesPage>> getSharedNotes({required int page});
}
