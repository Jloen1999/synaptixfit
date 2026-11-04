import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/challenge_reference_dto.dart';
import '../../../domain/enums/challenge_link_type.dart';
import '../../../domain/models/challenges/challenge_references.dart';

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

  /// Entregas y exámenes que vencen en [from, to] (lo filtra el servidor).
  Future<List<ChallengeDeadlineDto>> deadlinesBetween(
    String? subjectId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/planner/deadlines',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'subjectId': ?subjectId,
        'page': 0,
        'size': 100,
      },
    );
    return ChallengeDeadlinePageDto.fromJson(response.data!).items;
  }

  Future<String> fileUrl(String fileId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/files/$fileId/download-url',
    );
    return ChallengeSignedUrlDto.fromJson(response.data!).url;
  }

  /// Días de la rutina en curso que se pueden vincular a una tarea.
  Future<List<ChallengeLinkOption>> routineDayTargets() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/challenges/routine-day-targets',
    );
    return [
      for (final e in (response.data ?? const []).cast<Map<String, dynamic>>())
        ChallengeLinkOption(
          id: e['dayId'] as String,
          type: ChallengeLinkType.routineDay,
          title: e['routineName'] as String? ?? '',
          weekNumber: (e['weekNumber'] as num?)?.toInt(),
          dayNumber: (e['dayNumber'] as num?)?.toInt(),
        ),
    ];
  }
}
