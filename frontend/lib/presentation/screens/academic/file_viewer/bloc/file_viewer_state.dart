part of 'file_viewer_bloc.dart';

@freezed
abstract class FileViewerState with _$FileViewerState {
  const factory FileViewerState({
    @Default('') String fileId,
    @Default(true) bool loading,
    AppError? error,
    FileContent? content,
    @Default(DocumentAvailability.none) DocumentAvailability availability,
    @Default(false) bool busy,
    AppError? actionError,
    @Default(false) bool deleted,
    ({String materialId, bool practice})? navigation,
  }) = _FileViewerState;
}
