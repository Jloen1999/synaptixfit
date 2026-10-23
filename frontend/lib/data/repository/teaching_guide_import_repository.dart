import '../../domain/models/academic/subject_file.dart';
import '../../domain/models/academic/teaching_guide_import.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/teaching_guide_import_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/academic/dto/teaching_guide_import_dtos.dart';
import '../remote_data_source/academic/files_remote_data_source.dart';
import '../remote_data_source/academic/teaching_guide_imports_remote_data_source.dart';

/// Implementa [TeachingGuideImportRepositoryContract] con
/// [TeachingGuideImportsRemoteDataSource]; la subida del PDF reutiliza
/// [FilesRemoteDataSource.uploadBytes].
class TeachingGuideImportRepository
    implements TeachingGuideImportRepositoryContract {
  TeachingGuideImportRepository(this._remote, this._files);

  final TeachingGuideImportsRemoteDataSource _remote;
  final FilesRemoteDataSource _files;

  /// URL de subida → PUT al almacenamiento → alta de la importación (202).
  @override
  Future<AppResult<TeachingGuideImport>> start(
    FileUploadPayload payload, {
    String? targetSubjectId,
    void Function(double progress)? onProgress,
  }) => RepositoryErrorHandler.guard(() async {
    final size = payload.bytes.length;
    final ticket = await _remote.requestUpload(
      fileName: payload.fileName,
      mimeType: payload.mimeType,
      sizeBytes: size,
    );
    await _files.uploadBytes(
      ticket,
      payload.bytes,
      mimeType: payload.mimeType,
      onProgress: onProgress,
    );
    final started = await _remote.start(
      objectKey: ticket.objectKey,
      fileName: payload.fileName,
      mimeType: payload.mimeType,
      sizeBytes: size,
      targetSubjectId: targetSubjectId,
    );
    return started.toDomain();
  });

  @override
  Future<AppResult<TeachingGuideImport>> get(String importId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.get(importId)).toDomain(),
      );

  @override
  Future<AppResult<TeachingGuideImport>> retry(String importId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.retry(importId)).toDomain(),
      );

  @override
  Future<AppResult<TeachingGuideImportResult>> apply(
    String importId, {
    String? subjectId,
    required GuideDraft draft,
    required bool createDeadlines,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.apply(
      importId,
      subjectId: subjectId,
      guide: GuideDraftDto.fromDomain(draft),
      createDeadlines: createDeadlines,
    )).toDomain(),
  );

  @override
  Future<AppResult<Unit>> discard(String importId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.discard(importId);
        return unit;
      });
}
