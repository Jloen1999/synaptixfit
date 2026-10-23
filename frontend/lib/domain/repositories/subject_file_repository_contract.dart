import '../models/academic/subject_file.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Archivos de las asignaturas (subida y descarga con URL firmada).
abstract interface class SubjectFileRepositoryContract {
  Future<AppResult<List<SubjectFile>>> getFiles(String subjectId);

  /// Pide la URL de subida, sube el binario y confirma el archivo.
  /// [onProgress] recibe el avance de la subida entre 0 y 1.
  Future<AppResult<SubjectFile>> uploadFile(
    String subjectId,
    FileUploadPayload payload, {
    void Function(double progress)? onProgress,
  });

  /// Metadatos y URL firmada; descarga los bytes si [withBytes].
  Future<AppResult<FileContent>> getFileContent(
    String fileId, {
    required bool withBytes,
  });

  Future<AppResult<Unit>> deleteFile(String fileId);
}
