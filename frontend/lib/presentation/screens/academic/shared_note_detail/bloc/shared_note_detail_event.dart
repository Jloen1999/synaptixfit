part of 'shared_note_detail_bloc.dart';

@freezed
sealed class SharedNoteDetailEvent with _$SharedNoteDetailEvent {
  const factory SharedNoteDetailEvent.started(String noteId) =
      SharedNoteDetailStarted;

  const factory SharedNoteDetailEvent.copyRequested() =
      SharedNoteDetailCopyRequested;
}
