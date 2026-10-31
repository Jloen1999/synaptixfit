import '../../domain/enums/visibility.dart';
import '../../domain/models/academic/note.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/note_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/academic/notes_remote_data_source.dart';

class NoteRepository implements NoteRepositoryContract {
  NoteRepository(this._remote);

  final NotesRemoteDataSource _remote;

  /// Límite de páginas al recorrer todos los apuntes.
  static const _maxPages = 10;

  static const _sharedPageSize = 20;

  @override
  Future<AppResult<List<Note>>> getNotes({String? subjectId}) =>
      RepositoryErrorHandler.guard(() async {
        final notes = <Note>[];
        var page = 0;
        var totalPages = 1;
        while (page < totalPages && page < _maxPages) {
          final result = await _remote.getNotes(
            subjectId: subjectId,
            page: page,
          );
          notes.addAll(result.items.map((n) => n.toDomain()));
          totalPages = result.totalPages;
          page++;
        }
        return notes;
      });

  @override
  Future<AppResult<Note>> getNote(String noteId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getNote(noteId)).toDomain(),
      );

  @override
  Future<AppResult<Note>> createNote({
    String? subjectId,
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.createNote({
      'subjectId': ?subjectId,
      'title': title,
      'content': content,
      'visibility': visibility.apiValue,
      'quickNote': quickNote,
    })).toDomain(),
  );

  @override
  Future<AppResult<Note>> updateNote(
    String noteId, {
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
    String? subjectId,
    bool detachSubject = false,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.updateNote(noteId, {
      'title': title,
      'content': content,
      'visibility': visibility.apiValue,
      'quickNote': quickNote,
      'subjectId': ?subjectId,
      if (detachSubject) 'detachSubject': true,
    })).toDomain(),
  );

  @override
  Future<AppResult<Unit>> deleteNote(String noteId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deleteNote(noteId);
        return unit;
      });

  @override
  Future<AppResult<SharedNotesPage>> getSharedNotes({required int page}) =>
      RepositoryErrorHandler.guard(
        () async =>
            (await _remote.getSharedNotes(page, _sharedPageSize)).toDomain(),
      );
}
