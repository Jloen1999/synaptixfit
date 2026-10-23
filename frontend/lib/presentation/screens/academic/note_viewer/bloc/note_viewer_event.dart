part of 'note_viewer_bloc.dart';

@freezed
sealed class NoteViewerEvent with _$NoteViewerEvent {
  const factory NoteViewerEvent.started(String noteId) = NoteViewerStarted;

  const factory NoteViewerEvent.refreshed() = NoteViewerRefreshed;

  const factory NoteViewerEvent.deleteRequested() = NoteViewerDeleteRequested;

  /// Registra el apunte como material y abre su repaso o su práctica.
  const factory NoteViewerEvent.materialRequested({required bool practice}) =
      NoteViewerMaterialRequested;
}
