part of 'note_editor_bloc.dart';

@freezed
abstract class NoteEditorState with _$NoteEditorState {
  const factory NoteEditorState({
    /// Privacidad del perfil: las visibilidades mayores no se ofrecen.
    @Default(Visibility.private) Visibility profilePrivacy,

    /// Visibilidad con la que se abre el editor, ya rebajada a la del perfil.
    @Default(Visibility.private) Visibility initialVisibility,
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

  const NoteEditorState._();

  /// [requested] rebajada a la privacidad del perfil (el servidor hace lo mismo
  /// al guardar; aquí solo sirve para mostrar lo que de verdad verán los demás).
  Visibility allowed(Visibility requested) =>
      requested.isAllowedBy(profilePrivacy) ? requested : profilePrivacy;
}
