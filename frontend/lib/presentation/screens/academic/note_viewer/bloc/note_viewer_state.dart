part of 'note_viewer_bloc.dart';

@freezed
abstract class NoteViewerState with _$NoteViewerState {
  const factory NoteViewerState({
    @Default('') String noteId,
    @Default(true) bool loading,
    AppError? error,
    Note? note,
    @Default(DocumentAvailability.none) DocumentAvailability availability,
    @Default(false) bool busy,
    AppError? actionError,
    @Default(false) bool deleted,
    ({String materialId, bool practice})? navigation,
  }) = _NoteViewerState;
}
