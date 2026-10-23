import '../../domain/models/academic/subject_file.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/subject_file_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/academic/files_remote_data_source.dart';

class SubjectFileRepository implements SubjectFileRepositoryContract {
  SubjectFileRepository(this._remote);

  final FilesRemoteDataSource _remote;

  @override
  Future<AppResult<List<SubjectFile>>> getFiles(String subjectId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getFiles(
          subjectId,
        )).map((f) => f.toDomain()).toList(),
      );

  /// Flujo de tres pasos: URL de subida → PUT al almacenamiento → confirmación.
  @override
  Future<AppResult<SubjectFile>> uploadFile(
    String subjectId,
    FileUploadPayload payload, {
    void Function(double progress)? onProgress,
  }) => RepositoryErrorHandler.guard(() async {
    final size = payload.bytes.length;
    final ticket = await _remote.requestUpload(
      subjectId,
      fileName: payload.fileName,
      mimeType: payload.mimeType,
      sizeBytes: size,
    );
    await _remote.uploadBytes(
      ticket,
      payload.bytes,
      mimeType: payload.mimeType,
      onProgress: onProgress,
    );
    final file = await _remote.confirmUpload(
      subjectId,
      objectKey: ticket.objectKey,
      fileName: payload.fileName,
      mimeType: payload.mimeType,
      sizeBytes: size,
    );
    return file.toDomain();
  });

  @override
  Future<AppResult<FileContent>> getFileContent(
    String fileId, {
    required bool withBytes,
  }) => RepositoryErrorHandler.guard(() async {
    final file = await _remote.getFile(fileId);
    final url = await _remote.getDownloadUrl(fileId);
    final bytes = withBytes ? await _remote.download(url) : null;
    return FileContent(
      file: file.toDomain(),
      url: url.toDomain(),
      bytes: bytes,
    );
  });

  @override
  Future<AppResult<Unit>> deleteFile(String fileId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deleteFile(fileId);
        return unit;
      });
}
