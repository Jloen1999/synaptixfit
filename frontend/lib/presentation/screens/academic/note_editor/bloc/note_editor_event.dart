part of 'note_editor_bloc.dart';

@freezed
sealed class NoteEditorEvent with _$NoteEditorEvent {
  /// [noteId] nulo = apunte nuevo.
  const factory NoteEditorEvent.started({
    String? noteId,
    String? subjectId,
    @Default(false) bool quickNote,
  }) = NoteEditorStarted;

  const factory NoteEditorEvent.submitted({
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
    String? subjectId,
  }) = NoteEditorSubmitted;
}
