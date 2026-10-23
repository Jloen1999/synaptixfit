part of 'file_viewer_bloc.dart';

@freezed
sealed class FileViewerEvent with _$FileViewerEvent {
  /// [inlinePdf]: descargar el PDF para pintarlo dentro de la app.
  const factory FileViewerEvent.started(
    String fileId, {
    @Default(true) bool inlinePdf,
  }) = FileViewerStarted;

  const factory FileViewerEvent.deleteRequested() = FileViewerDeleteRequested;

  const factory FileViewerEvent.materialRequested({required bool practice}) =
      FileViewerMaterialRequested;
}
