import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/file_dtos.dart';
import 'dto/teaching_guide_import_dtos.dart';

/// Endpoints de `/api/v1/teaching-guide-imports` (importar planes docentes).
/// El PDF se sube con [FilesRemoteDataSource.uploadBytes] a la URL firmada.
class TeachingGuideImportsRemoteDataSource {
  TeachingGuideImportsRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/teaching-guide-imports';

  Future<FileUploadTicketDto> requestUpload({
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/upload-url',
      data: {
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
      },
    );
    return FileUploadTicketDto.fromJson(response.data!);
  }

  Future<TeachingGuideImportDto> start({
    required String objectKey,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    String? targetSubjectId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _base,
      data: {
        'objectKey': objectKey,
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'targetSubjectId': ?targetSubjectId,
      },
    );
    return TeachingGuideImportDto.fromJson(response.data!);
  }

  Future<TeachingGuideImportDto> get(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/$id');
    return TeachingGuideImportDto.fromJson(response.data!);
  }

  Future<TeachingGuideImportDto> retry(String id) async {
    final response = await _dio.post<Map<String, dynamic>>('$_base/$id/retry');
    return TeachingGuideImportDto.fromJson(response.data!);
  }

  Future<ApplyImportResultDto> apply(
    String id, {
    String? subjectId,
    required GuideDraftDto guide,
    required bool createDeadlines,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/$id/apply',
      data: {
        'subjectId': ?subjectId,
        'guide': guide.toJson(),
        'createDeadlines': createDeadlines,
      },
    );
    return ApplyImportResultDto.fromJson(response.data!);
  }

  Future<void> discard(String id) => _dio.delete<void>('$_base/$id');
}
