import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/note_dtos.dart';
import 'dto/study_dtos.dart';

/// Endpoints del asistente de estudio con IA (`/api/v1/study`).
class StudyRemoteDataSource {
  StudyRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/study';

  String _docPath(String sourceType, String sourceId) =>
      '$_base/sources/$sourceType/$sourceId/documents';

  Future<StudyDocumentDto> getDocument(
    String sourceType,
    String sourceId,
    String type,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_docPath(sourceType, sourceId)}/$type',
    );
    return StudyDocumentDto.fromJson(response.data!);
  }

  Future<StudyDocumentDto> generateDocument(
    String sourceType,
    String sourceId,
    String type,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${_docPath(sourceType, sourceId)}/$type',
    );
    return StudyDocumentDto.fromJson(response.data!);
  }

  Future<DocumentAvailabilityDto> getAvailability(
    String sourceType,
    String sourceId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _docPath(sourceType, sourceId),
    );
    return DocumentAvailabilityDto.fromJson(response.data!);
  }

  Future<ArtifactDto> generateArtifact(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/generations',
      data: body,
    );
    return ArtifactDto.fromJson(response.data!);
  }

  Future<NoteDto> saveAsNote(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/generations/notes',
      data: body,
    );
    return NoteDto.fromJson(response.data!);
  }

  Future<SavedQuizDto> saveAsQuiz(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/generations/quizzes',
      data: body,
    );
    return SavedQuizDto.fromJson(response.data!);
  }
}
