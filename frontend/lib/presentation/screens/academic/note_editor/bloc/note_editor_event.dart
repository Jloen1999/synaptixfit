part of 'note_editor_bloc.dart';

@freezed
sealed class NoteEditorEvent with _$NoteEditorEvent {
  /// [noteId] nulo = apunte nuevo. [accountId] separa los borradores de cada
  /// cuenta en el mismo teléfono.
  const factory NoteEditorEvent.started({
    String? noteId,
    @Default('') String accountId,
    String? subjectId,
    @Default(false) bool quickNote,

    /// Privacidad del perfil: un apunte no se comparte más allá de ella.
    @Default(Visibility.private) Visibility profilePrivacy,
  }) = NoteEditorStarted;

  /// La privacidad del perfil cambió (p. ej., tras «Cambiar privacidad»).
  const factory NoteEditorEvent.profilePrivacyChanged(Visibility privacy) =
      NoteEditorProfilePrivacyChanged;

  /// Guarda en el teléfono lo escrito hasta ahora (lo pide la pantalla cada
  /// pocos segundos si hay cambios).
  const factory NoteEditorEvent.draftChanged({
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
    String? subjectId,
  }) = NoteEditorDraftChanged;

  /// «Recuperar» del aviso: la pantalla ya ha copiado el borrador.
  const factory NoteEditorEvent.draftRestored() = NoteEditorDraftRestored;

  /// «Descartar» del aviso o salir sin guardar: se borra el borrador.
  const factory NoteEditorEvent.draftDiscarded() = NoteEditorDraftDiscarded;

  const factory NoteEditorEvent.submitted({
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
    String? subjectId,
  }) = NoteEditorSubmitted;
}
