import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject_file.freezed.dart';

/// Archivo adjunto a una asignatura (el binario vive en el almacenamiento).
@freezed
abstract class SubjectFile with _$SubjectFile {
  const factory SubjectFile({
    required String id,
    required String subjectId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required bool aiReadable,
    DateTime? createdAt,
  }) = _SubjectFile;

  const SubjectFile._();

  bool get isPdf => mimeType == 'application/pdf';

  bool get isImage => mimeType.startsWith('image/');
}

/// Archivo elegido por el usuario para subirlo.
@freezed
abstract class FileUploadPayload with _$FileUploadPayload {
  const factory FileUploadPayload({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) = _FileUploadPayload;
}

/// URL firmada temporal para descargar un archivo.
@freezed
abstract class SignedUrl with _$SignedUrl {
  const factory SignedUrl({
    required String url,
    @Default(<String, String>{}) Map<String, String> headers,
    DateTime? expiresAt,
  }) = _SignedUrl;
}

/// Contenido descargado de un archivo para visualizarlo.
@freezed
abstract class FileContent with _$FileContent {
  const factory FileContent({
    required SubjectFile file,
    required SignedUrl url,
    Uint8List? bytes,
  }) = _FileContent;
}
