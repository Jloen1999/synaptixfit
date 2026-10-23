part of 'note_editor_bloc.dart';

@freezed
abstract class NoteEditorState with _$NoteEditorState {
  const factory NoteEditorState({
    @Default(true) bool loading,
    AppError? loadError,
    Note? note,
    @Default(<Subject>[]) List<Subject> subjects,
    String? initialSubjectId,
    @Default(false) bool initialQuickNote,
    @Default(false) bool saving,
    AppError? saveError,
    String? savedNoteId,
  }) = _NoteEditorState;
}
