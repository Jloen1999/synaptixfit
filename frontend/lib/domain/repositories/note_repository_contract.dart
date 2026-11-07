import '../enums/shared_notes_scope.dart';
import '../enums/visibility.dart';
import '../models/academic/note.dart';
import '../models/academic/note_scan.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Apuntes propios y compartidos.
abstract interface class NoteRepositoryContract {
  Future<AppResult<List<Note>>> getNotes({String? subjectId});

  /// Apuntes sin asignatura, los más recientes primero.
  Future<AppResult<List<Note>>> getUnassignedNotes();

  /// Cambia solo la asignatura del apunte.
  Future<AppResult<Note>> moveNoteToSubject(
    String noteId, {
    required String subjectId,
  });

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

  Future<AppResult<SharedNoteSummaryPage>> getSharedNotes({
    required int page,
    SharedNotesScope scope = SharedNotesScope.all,
    String? authorId,
    String? search,
    int size = 20,
  });

  Future<AppResult<SharedNote>> getSharedNote(String noteId);

  Future<AppResult<Note>> copySharedNote(String noteId);

  /// Lee fotos de apuntes en papel y devuelve un borrador (no guarda nada).
  Future<AppResult<ScannedNoteDraft>> readNotePhotos(
    List<NotePhotoUpload> photos,
  );
}
