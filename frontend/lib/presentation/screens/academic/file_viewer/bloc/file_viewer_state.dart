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

    /// Qué se pidió con [busy]: repasar (false) o practicar (true), para que
    /// el botón pulsado diga que está cargando.
    bool? requestedPractice,
    AppError? actionError,
    @Default(false) bool deleted,
    ({String materialId, bool practice})? navigation,
  }) = _FileViewerState;
}
