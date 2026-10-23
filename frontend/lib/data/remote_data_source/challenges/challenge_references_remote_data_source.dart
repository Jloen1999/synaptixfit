import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/challenge_api_values.dart';
import 'dto/challenge_reference_dto.dart';

/// Lecturas de otros módulos que necesitan los retos: asignaturas, apuntes,
/// archivos, entregas y bloques del planificador.
class ChallengeReferencesRemoteDataSource {
  ChallengeReferencesRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<List<ChallengeSubjectDto>> subjects() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/subjects',
      queryParameters: {'archived': false},
    );
    return response.data!
        .map((e) => ChallengeSubjectDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Apuntes de una asignatura o, sin asignatura, los que no tienen ninguna.
  Future<List<ChallengeNoteDto>> notes(String? subjectId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/notes',
      queryParameters: {
        'subjectId': ?subjectId,
        if (subjectId == null) 'unassignedOnly': true,
        'page': 0,
        'size': 100,
      },
    );
    return ChallengeNotePageDto.fromJson(response.data!).items;
  }

  Future<List<ChallengeFileDto>> files(String subjectId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/subjects/$subjectId/files',
    );
    return response.data!
        .map((e) => ChallengeFileDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChallengeDeadlineDto>> upcomingDeadlines(
    String? subjectId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/planner/deadlines',
      queryParameters: {
        'upcoming': true,
        'subjectId': ?subjectId,
        'page': 0,
        'size': 100,
      },
    );
    return ChallengeDeadlinePageDto.fromJson(response.data!).items;
  }

  Future<List<ChallengeBlockDto>> blocks({
    required DateTime from,
    required DateTime to,
    String? subjectId,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/planner/blocks',
      queryParameters: {
        'from': ChallengeApiValues.toInstant(from),
        'to': ChallengeApiValues.toInstant(to),
        'subjectId': ?subjectId,
      },
    );
    return response.data!
        .map((e) => ChallengeBlockDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> fileUrl(String fileId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/files/$fileId/download-url',
    );
    return ChallengeSignedUrlDto.fromJson(response.data!).url;
  }
}
