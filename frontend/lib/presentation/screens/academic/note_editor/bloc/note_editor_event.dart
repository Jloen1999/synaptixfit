part of 'note_editor_bloc.dart';

@freezed
sealed class NoteEditorEvent with _$NoteEditorEvent {
  /// [noteId] nulo = apunte nuevo.
  const factory NoteEditorEvent.started({
    String? noteId,
    String? subjectId,
    @Default(false) bool quickNote,

    /// Privacidad del perfil: un apunte no se comparte más allá de ella.
    @Default(Visibility.private) Visibility profilePrivacy,
  }) = NoteEditorStarted;

  /// La privacidad del perfil cambió (p. ej., tras «Cambiar privacidad»).
  const factory NoteEditorEvent.profilePrivacyChanged(Visibility privacy) =
      NoteEditorProfilePrivacyChanged;

  const factory NoteEditorEvent.submitted({
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
    String? subjectId,
  }) = NoteEditorSubmitted;
}
