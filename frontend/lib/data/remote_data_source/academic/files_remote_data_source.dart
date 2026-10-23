import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/file_dtos.dart';

/// Endpoints de archivos (`/api/v1/subjects/{id}/files`, `/api/v1/files`) y
/// transferencia directa al almacenamiento con URLs prefirmadas.
class FilesRemoteDataSource {
  FilesRemoteDataSource(ApiClient client, {Dio? storageDio})
    : _dio = client.dio,
      _storage = storageDio ?? Dio();

  final Dio _dio;

  /// Cliente sin el token de la API: solo habla con el almacenamiento.
  final Dio _storage;

  Future<List<SubjectFileDto>> getFiles(String subjectId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/subjects/$subjectId/files',
    );
    return (response.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(SubjectFileDto.fromJson)
        .toList();
  }

  Future<FileUploadTicketDto> requestUpload(
    String subjectId, {
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/subjects/$subjectId/files/upload-url',
      data: {
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
      },
    );
    return FileUploadTicketDto.fromJson(response.data!);
  }

  /// Sube el binario a la URL prefirmada con las cabeceras indicadas.
  Future<void> uploadBytes(
    FileUploadTicketDto ticket,
    Uint8List bytes, {
    required String mimeType,
    void Function(double progress)? onProgress,
  }) => _storage.request<void>(
    ticket.uploadUrl,
    data: bytes,
    options: Options(
      method: ticket.method,
      headers: {
        Headers.contentTypeHeader: mimeType,
        ...ticket.headers,
        Headers.contentLengthHeader: bytes.length,
      },
    ),
    onSendProgress: onProgress == null
        ? null
        : (sent, total) {
            if (total > 0) onProgress(sent / total);
          },
  );

  Future<SubjectFileDto> confirmUpload(
    String subjectId, {
    required String objectKey,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/subjects/$subjectId/files',
      data: {
        'objectKey': objectKey,
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
      },
    );
    return SubjectFileDto.fromJson(response.data!);
  }

  Future<SubjectFileDto> getFile(String fileId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/files/$fileId',
    );
    return SubjectFileDto.fromJson(response.data!);
  }

  Future<SignedUrlDto> getDownloadUrl(String fileId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/files/$fileId/download-url',
    );
    return SignedUrlDto.fromJson(response.data!);
  }

  /// Descarga el binario desde la URL firmada.
  Future<Uint8List> download(SignedUrlDto url) async {
    final response = await _storage.request<List<int>>(
      url.url,
      options: Options(
        method: url.method,
        headers: url.headers,
        responseType: ResponseType.bytes,
      ),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  Future<void> deleteFile(String fileId) =>
      _dio.delete<void>('/api/v1/files/$fileId');
}
